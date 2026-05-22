// ═══════════════════════════════════════════════════════════════════════════════
//  SimSphereActor.cpp
//  ─────────────────────────────────────────────────────────────────────────────
//  Runtime: Tick() pushes 8 MPC scalars + 1 vector per frame. GPU material
//  reads MPC, samples WaveDataTable via curve, samples MediaTexture as base
//  layer, computes Fresnel + WPO, ships to Lumen + TSR + DLSS 4 MFG.
//
//  Total frame cost on RTX 5070 Ti: ~3.3ms rendered → 120fps via MFG ×4.
//
//  Lines: ~180                  Author: jdw274@cornell.edu          v1.0
// ═══════════════════════════════════════════════════════════════════════════════
#include "SimSphereActor.h"

#include "Components/StaticMeshComponent.h"
#include "Materials/MaterialParameterCollection.h"
#include "Materials/MaterialParameterCollectionInstance.h"
#include "Engine/DataTable.h"
#include "Curves/CurveFloat.h"
#include "MediaPlayer.h"
#include "MediaTexture.h"
#include "EnhancedInputComponent.h"
#include "EnhancedInputSubsystems.h"
#include "InputMappingContext.h"
#include "GameFramework/PlayerController.h"
#include "Kismet/GameplayStatics.h"
#include "Engine/World.h"
#include "Engine/StaticMesh.h"
#include "Dom/JsonObject.h"
#include "Dom/JsonValue.h"
#include "Serialization/JsonReader.h"
#include "Serialization/JsonWriter.h"
#include "Serialization/JsonSerializer.h"
#include "Misc/DateTime.h"
#include "UObject/ConstructorHelpers.h"

DEFINE_LOG_CATEGORY_STATIC(LogBlurSim, Log, All);

// ─── Construction ─────────────────────────────────────────────────────────────
ASimSphereActor::ASimSphereActor()
{
	PrimaryActorTick.bCanEverTick = true;

	RootScene = CreateDefaultSubobject<USceneComponent>(TEXT("RootScene"));
	SetRootComponent(RootScene);

	SphereMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("SphereMesh"));
	SphereMesh->SetupAttachment(RootScene);
	SphereMesh->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	SphereMesh->SetCollisionResponseToAllChannels(ECR_Block);
	SphereMesh->bEvaluateWorldPositionOffset = true;
	SphereMesh->WorldPositionOffsetDisableDistance = 1000000; // Always evaluate WPO

	static ConstructorHelpers::FObjectFinder<UStaticMesh> MetaCubeSphereMeshFinder(TEXT("/Game/Sim/Meshes/SM_OmniSphere.SM_OmniSphere"));
	if (MetaCubeSphereMeshFinder.Succeeded())
	{
		SphereMesh->SetStaticMesh(MetaCubeSphereMeshFinder.Object);
	}
	else
	{
		static ConstructorHelpers::FObjectFinder<UStaticMesh> SphereMeshFinder(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
		if (SphereMeshFinder.Succeeded())
		{
			SphereMesh->SetStaticMesh(SphereMeshFinder.Object);
		}
	}

	ApplyCrystalNeonTennisStyle();
}

// ─── BeginPlay — bind MPC instance, register input, kick off media ────────────
void ASimSphereActor::BeginPlay()
{
	Super::BeginPlay();
	ApplyCrystalNeonTennisStyle();

	if (UWorld* W = GetWorld(); W && MPC_Sim)
	{
		MPCInst = W->GetParameterCollectionInstance(MPC_Sim);
	}

	if (bUseMediaTexture && BaseMediaPlayer)
	{
		BaseMediaPlayer->OpenSource(nullptr); // user-defined source set in Blueprint
		BaseMediaPlayer->Play();
	}

	// Register the Enhanced Input mapping context for the local player
	if (APlayerController* PC = UGameplayStatics::GetPlayerController(this, 0))
	{
		if (auto* Subsys = ULocalPlayer::GetSubsystem<UEnhancedInputLocalPlayerSubsystem>(PC->GetLocalPlayer()))
		{
			if (IMC_Sim) Subsys->AddMappingContext(IMC_Sim, 0);
		}
		EnableInput(PC);
		if (auto* EIC = Cast<UEnhancedInputComponent>(InputComponent))
		{
			SetupPlayerInputComponent(EIC);
		}
	}

	UE_LOG(LogBlurSim, Log, TEXT("[SimSphere] BeginPlay complete — MPC=%s · DataTable=%s · Media=%s"),
		*GetNameSafe(MPC_Sim), *GetNameSafe(WaveDataTable),
		bUseMediaTexture ? TEXT("ON") : TEXT("off"));
}

// ─── Tick — the entire runtime cost lives here. Keep it cheap. ────────────────
void ASimSphereActor::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	WaveTime       += DeltaTime * WaveSpeed;
	ImpactStrength *= FMath::Pow(ImpactDecayRate, DeltaTime * 60.f);  // 60fps-normalized decay

	if (bUseBakedDataTable) SampleBakedFrame();
	PushMPCParameters(DeltaTime);
}

// ─── PushMPCParameters — 8 scalars + 1 vector per frame ──────────────────────
void ASimSphereActor::PushMPCParameters(float DeltaTime)
{
	if (!MPCInst) return;

	// Sample wave profile curve at normalized time (loops every 10s)
	float CurveMultiplier = 1.f;
	if (WaveProfileCurve)
	{
		const float NormT = FMath::Fmod(WaveTime, 10.f) / 10.f;
		CurveMultiplier = WaveProfileCurve->GetFloatValue(NormT);
	}

	MPCInst->SetScalarParameterValue(TEXT("Amplitude"),         Amplitude * CurveMultiplier);
	MPCInst->SetScalarParameterValue(TEXT("Frequency"),         Frequency);
	MPCInst->SetScalarParameterValue(TEXT("WaveTime"),          WaveTime);
	MPCInst->SetScalarParameterValue(TEXT("Damping"),           Damping);
	MPCInst->SetScalarParameterValue(TEXT("ImpactX"),           ImpactUV.X);
	MPCInst->SetScalarParameterValue(TEXT("ImpactY"),           ImpactUV.Y);
	MPCInst->SetScalarParameterValue(TEXT("ImpactStrength"),    ImpactStrength);
	MPCInst->SetScalarParameterValue(TEXT("EmissiveIntensity"), EmissiveIntensity);
	MPCInst->SetScalarParameterValue(TEXT("FresnelPower"),      FresnelPower);
	MPCInst->SetScalarParameterValue(TEXT("CrystalWhiteness"),  CrystalWhiteness);
	MPCInst->SetScalarParameterValue(TEXT("GlassCoat"),         GlassCoat);
	MPCInst->SetScalarParameterValue(TEXT("NeonFuzz"),          NeonFuzz);
	MPCInst->SetScalarParameterValue(TEXT("VolumetricFogDensity"), VolumetricFogDensity);
	MPCInst->SetScalarParameterValue(TEXT("RubberAccentStrength"), RubberAccentStrength);
	MPCInst->SetScalarParameterValue(TEXT("WaveGlassDistortion"), WaveGlassDistortion);
	MPCInst->SetVectorParameterValue(TEXT("BaseColor"),         BaseColor);
	MPCInst->SetVectorParameterValue(TEXT("AccentColor"),       AccentColor);

	// Push view direction (drives view-dependent Fresnel/specular layer)
	if (APlayerController* PC = UGameplayStatics::GetPlayerController(this, 0))
	{
		FVector CamLoc; FRotator CamRot;
		PC->GetPlayerViewPoint(CamLoc, CamRot);
		const FVector ToCam = (CamLoc - GetActorLocation()).GetSafeNormal();
		MPCInst->SetVectorParameterValue(TEXT("ViewDir"),
			FLinearColor(ToCam.X, ToCam.Y, ToCam.Z, 0.f));
	}
}

// ─── SampleBakedFrame — read pre-solved physics from WaveDataTable ────────────
void ASimSphereActor::SampleBakedFrame()
{
	if (!WaveDataTable) return;

	const TArray<FName> Rows = WaveDataTable->GetRowNames();
	if (Rows.Num() == 0) return;

	CurrentFrameIdx = FMath::FloorToInt(WaveTime * 120.f) % Rows.Num();   // 120fps assumed
	const FName Key = Rows[CurrentFrameIdx];
	if (FWaveFrameRow* Row = WaveDataTable->FindRow<FWaveFrameRow>(Key, TEXT("SimTick")))
	{
		// Modulate live params by baked solution — this is the Hawkeye replay layer
		Amplitude = FMath::Lerp(Amplitude, Row->Amplitude, 0.5f);
		Frequency = FMath::Lerp(Frequency, Row->Frequency, 0.5f);
	}
}

// ─── ApplyJSONState — round-trip the entire sim state through one string ─────
void ASimSphereActor::ApplyJSONState(const FString& JSONString)
{
	TSharedPtr<FJsonObject> Root;
	const auto Reader = TJsonReaderFactory<>::Create(JSONString);
	if (!FJsonSerializer::Deserialize(Reader, Root) || !Root.IsValid())
	{
		UE_LOG(LogBlurSim, Warning, TEXT("[SimSphere] JSON parse failed"));
		return;
	}

	if (auto Physics = Root->GetObjectField(TEXT("physics")))
	{
		auto Get = [&Physics](const FString& K, float Fallback) -> float
		{
			const TSharedPtr<FJsonObject> P = Physics->GetObjectField(K);
			return P.IsValid() ? P->GetNumberField(TEXT("value")) : Fallback;
		};
		Amplitude = Get(TEXT("amplitude"), Amplitude);
		Frequency = Get(TEXT("frequency"), Frequency);
		WaveSpeed = Get(TEXT("wave_speed"), WaveSpeed);
		Damping   = Get(TEXT("damping"),    Damping);
	}

	if (auto Material = Root->GetObjectField(TEXT("material")))
	{
		const TArray<TSharedPtr<FJsonValue>>* ColorArr = nullptr;
		if (Material->TryGetArrayField(TEXT("base_color"), ColorArr) && ColorArr->Num() >= 3)
		{
			BaseColor.R = (*ColorArr)[0]->AsNumber();
			BaseColor.G = (*ColorArr)[1]->AsNumber();
			BaseColor.B = (*ColorArr)[2]->AsNumber();
			BaseColor.A = ColorArr->Num() > 3 ? (*ColorArr)[3]->AsNumber() : 1.f;
		}

		const TArray<TSharedPtr<FJsonValue>>* AccentArr = nullptr;
		if (Material->TryGetArrayField(TEXT("accent_color"), AccentArr) && AccentArr->Num() >= 3)
		{
			AccentColor.R = (*AccentArr)[0]->AsNumber();
			AccentColor.G = (*AccentArr)[1]->AsNumber();
			AccentColor.B = (*AccentArr)[2]->AsNumber();
			AccentColor.A = AccentArr->Num() > 3 ? (*AccentArr)[3]->AsNumber() : 1.f;
		}

		double Emi = 0; if (Material->TryGetNumberField(TEXT("emissive_intensity"), Emi)) EmissiveIntensity = Emi;
		double Frp = 0; if (Material->TryGetNumberField(TEXT("fresnel_power"),      Frp)) FresnelPower      = Frp;
		double Cw = 0; if (Material->TryGetNumberField(TEXT("crystal_whiteness"), Cw)) CrystalWhiteness = FMath::Clamp(static_cast<float>(Cw), 0.0f, 1.0f);
		double Gc = 0; if (Material->TryGetNumberField(TEXT("glass_coat"), Gc)) GlassCoat = FMath::Clamp(static_cast<float>(Gc), 0.0f, 1.0f);
		double Nf = 0; if (Material->TryGetNumberField(TEXT("neon_fuzz"), Nf)) NeonFuzz = FMath::Max(0.0f, static_cast<float>(Nf));
		double Vf = 0; if (Material->TryGetNumberField(TEXT("volumetric_fog_density"), Vf)) VolumetricFogDensity = FMath::Max(0.0f, static_cast<float>(Vf));
		double Ra = 0; if (Material->TryGetNumberField(TEXT("rubber_accent_strength"), Ra)) RubberAccentStrength = FMath::Max(0.0f, static_cast<float>(Ra));
		double Wg = 0; if (Material->TryGetNumberField(TEXT("wave_glass_distortion"), Wg)) WaveGlassDistortion = FMath::Max(0.0f, static_cast<float>(Wg));
	}

	UE_LOG(LogBlurSim, Log, TEXT("[SimSphere] Applied JSON: Amp=%.2f Freq=%.2f Speed=%.2f"),
		Amplitude, Frequency, WaveSpeed);
}

// ─── DumpJSONState — serialize current state to wire format ──────────────────
FString ASimSphereActor::DumpJSONState() const
{
	TSharedRef<FJsonObject> Root = MakeShared<FJsonObject>();

	auto MakeParam = [](float V, float Mn, float Mx, int32 Slot)
	{
		TSharedRef<FJsonObject> P = MakeShared<FJsonObject>();
		P->SetNumberField(TEXT("value"), V);
		P->SetNumberField(TEXT("min"),   Mn);
		P->SetNumberField(TEXT("max"),   Mx);
		P->SetNumberField(TEXT("mpc_slot"), Slot);
		return P;
	};

	TSharedRef<FJsonObject> Sim = MakeShared<FJsonObject>();
	Sim->SetStringField(TEXT("id"),           TEXT("wave_field_001"));
	Sim->SetStringField(TEXT("dumped_at"),    FDateTime::UtcNow().ToIso8601());
	Sim->SetNumberField(TEXT("wave_time"),    WaveTime);
	Sim->SetNumberField(TEXT("frame_idx"),    CurrentFrameIdx);
	Root->SetObjectField(TEXT("sim"), Sim);

	TSharedRef<FJsonObject> Physics = MakeShared<FJsonObject>();
	Physics->SetObjectField(TEXT("amplitude"),  MakeParam(Amplitude, 0.f, 5.f,  0));
	Physics->SetObjectField(TEXT("frequency"),  MakeParam(Frequency, 0.1f,10.f, 1));
	Physics->SetObjectField(TEXT("wave_speed"), MakeParam(WaveSpeed, 0.f, 5.f,  2));
	Physics->SetObjectField(TEXT("damping"),    MakeParam(Damping,   0.f, 1.f,  3));
	Root->SetObjectField(TEXT("physics"), Physics);

	TSharedRef<FJsonObject> Material = MakeShared<FJsonObject>();
	TArray<TSharedPtr<FJsonValue>> ColorArr;
	ColorArr.Add(MakeShared<FJsonValueNumber>(BaseColor.R));
	ColorArr.Add(MakeShared<FJsonValueNumber>(BaseColor.G));
	ColorArr.Add(MakeShared<FJsonValueNumber>(BaseColor.B));
	ColorArr.Add(MakeShared<FJsonValueNumber>(BaseColor.A));
	Material->SetArrayField(TEXT("base_color"), ColorArr);

	TArray<TSharedPtr<FJsonValue>> AccentArr;
	AccentArr.Add(MakeShared<FJsonValueNumber>(AccentColor.R));
	AccentArr.Add(MakeShared<FJsonValueNumber>(AccentColor.G));
	AccentArr.Add(MakeShared<FJsonValueNumber>(AccentColor.B));
	AccentArr.Add(MakeShared<FJsonValueNumber>(AccentColor.A));
	Material->SetArrayField(TEXT("accent_color"), AccentArr);

	Material->SetNumberField(TEXT("emissive_intensity"), EmissiveIntensity);
	Material->SetNumberField(TEXT("fresnel_power"),      FresnelPower);
	Material->SetNumberField(TEXT("crystal_whiteness"), CrystalWhiteness);
	Material->SetNumberField(TEXT("glass_coat"), GlassCoat);
	Material->SetNumberField(TEXT("neon_fuzz"), NeonFuzz);
	Material->SetNumberField(TEXT("volumetric_fog_density"), VolumetricFogDensity);
	Material->SetNumberField(TEXT("rubber_accent_strength"), RubberAccentStrength);
	Material->SetNumberField(TEXT("wave_glass_distortion"), WaveGlassDistortion);
	Root->SetObjectField(TEXT("material"), Material);

	FString Out;
	const auto Writer = TJsonWriterFactory<>::Create(&Out);
	FJsonSerializer::Serialize(Root, Writer);
	return Out;
}

// ─── OnImpact — inject a ripple at the world-space hit point ─────────────────
void ASimSphereActor::OnImpact(FVector HitWorldPos, float Strength)
{
	ImpactUV       = ProjectWorldToUV(HitWorldPos);
	ImpactStrength = FMath::Clamp(Strength, 0.f, 10.f);
	UE_LOG(LogBlurSim, Verbose, TEXT("[SimSphere] Impact at UV=(%.2f,%.2f) str=%.2f"),
		ImpactUV.X, ImpactUV.Y, ImpactStrength);
}

void ASimSphereActor::ResetSimulation()
{
	WaveTime         = 0.f;
	ImpactStrength   = 0.f;
	ImpactUV         = FVector2D::ZeroVector;
	CurrentFrameIdx  = 0;
	ApplyCrystalNeonTennisStyle();
	UE_LOG(LogBlurSim, Log, TEXT("[SimSphere] Reset"));
}

void ASimSphereActor::ApplyCrystalNeonTennisStyle()
{
	Amplitude = 0.96f;
	Frequency = 7.8f;
	WaveSpeed = 1.45f;
	Damping = 0.62f;
	BaseColor = FLinearColor(0.97f, 0.985f, 1.0f, 1.0f);
	AccentColor = FLinearColor(1.0f, 0.33f, 0.18f, 1.0f);
	EmissiveIntensity = 12.0f;
	FresnelPower = 3.8f;
	CrystalWhiteness = 0.98f;
	GlassCoat = 0.9f;
	NeonFuzz = 2.4f;
	VolumetricFogDensity = 1.35f;
	RubberAccentStrength = 0.92f;
	WaveGlassDistortion = 0.7f;
}

// ─── ProjectWorldToUV — sphere-projection from world position to (u,v) ───────
FVector2D ASimSphereActor::ProjectWorldToUV(FVector WorldPos) const
{
	const FVector Local = (WorldPos - GetActorLocation()).GetSafeNormal();
	const float   U     = 0.5f + FMath::Atan2(Local.Y, Local.X) / (2.f * PI);
	const float   V     = 0.5f - FMath::Asin(Local.Z) / PI;
	return FVector2D(U, V);
}

// ─── Enhanced Input wiring ────────────────────────────────────────────────────
void ASimSphereActor::SetupPlayerInputComponent(UEnhancedInputComponent* Input)
{
	if (!Input) return;
	if (IA_Orbit)     Input->BindAction(IA_Orbit,     ETriggerEvent::Triggered, this, &ASimSphereActor::HandleOrbit);
	if (IA_Zoom)      Input->BindAction(IA_Zoom,      ETriggerEvent::Triggered, this, &ASimSphereActor::HandleZoom);
	if (IA_Impact)    Input->BindAction(IA_Impact,    ETriggerEvent::Started,   this, &ASimSphereActor::HandleImpact);
	if (IA_WaveSpeed) Input->BindAction(IA_WaveSpeed, ETriggerEvent::Triggered, this, &ASimSphereActor::HandleWaveSpeed);
	if (IA_Reset)     Input->BindAction(IA_Reset,     ETriggerEvent::Started,   this, &ASimSphereActor::HandleReset);
}

void ASimSphereActor::HandleOrbit(const FInputActionValue& Value)
{
	const FVector2D Axis = Value.Get<FVector2D>();
	AddActorWorldRotation(FRotator(Axis.Y * 0.5f, Axis.X * 0.5f, 0.f));
}
void ASimSphereActor::HandleZoom(const FInputActionValue& Value)
{
	const float Z = Value.Get<float>();
	FVector S = GetActorScale3D() * (1.f + Z * 0.02f);
	S = S.ComponentMin(FVector(10.f)).ComponentMax(FVector(0.1f));
	SetActorScale3D(S);
}
void ASimSphereActor::HandleImpact(const FInputActionValue& Value)
{
	if (APlayerController* PC = UGameplayStatics::GetPlayerController(this, 0))
	{
		FHitResult Hit;
		if (PC->GetHitResultUnderCursor(ECC_Visibility, false, Hit))
			OnImpact(Hit.ImpactPoint, 4.0f);
		else
			OnImpact(GetActorLocation(), 2.0f);
	}
}
void ASimSphereActor::HandleWaveSpeed(const FInputActionValue& Value)
{
	WaveSpeed = FMath::Clamp(WaveSpeed + Value.Get<float>() * 0.1f, 0.f, 5.f);
}
void ASimSphereActor::HandleReset(const FInputActionValue& Value) { ResetSimulation(); }
