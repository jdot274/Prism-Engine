// ═══════════════════════════════════════════════════════════════════════════════
//  SimSphereActor.h
//  ─────────────────────────────────────────────────────────────────────────────
//  The single living asset of BlurFocusSim. A Nanite cube-sphere whose every
//  vertex is physically displaced per-tick by a pre-solved wave simulation,
//  rendered with Lumen + Fresnel + DLSS 4 MFG. Live-editable via MPC sliders.
//  XR-native. JSON state round-trip. Curve-driven everything.
//
//  Hybrid Baked-Live Volumetric Render (HBLVR) pattern:
//    OFFLINE  : WaveSolver.py → WaveDataTable + SimBase.mp4 + CurveAtlas
//    RUNTIME  : Tick() pushes 8 MPC scalars + 1 vector. GPU does the rest.
//    LIVE EDIT: WBP_SimControls sliders → MPC deltas → instant material refresh
//
//  Lines: ~120                  Author: jdw274@cornell.edu          v1.0
// ═══════════════════════════════════════════════════════════════════════════════
#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "InputActionValue.h"
#include "SimSphereActor.generated.h"

class UStaticMeshComponent;
class UMaterialParameterCollection;
class UMaterialParameterCollectionInstance;
class UDataTable;
class UCurveFloat;
class UMediaPlayer;
class UMediaTexture;
class UInputAction;
class UInputMappingContext;
class UEnhancedInputComponent;

// ─── DataTable row format produced by WaveSolver.py ───────────────────────────
USTRUCT(BlueprintType)
struct FWaveFrameRow : public FTableRowBase
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadWrite) float Time      = 0.f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite) float Amplitude = 0.f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite) float Frequency = 0.f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite) float Phase     = 0.f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite) float Envelope  = 0.f;
};

UCLASS(Blueprintable, BlueprintType, ClassGroup=(BlurFocusSim),
       meta=(DisplayName="Sim Sphere Actor"))
class BLURFOCUS_API ASimSphereActor : public AActor
{
	GENERATED_BODY()

public:
	ASimSphereActor();

	virtual void Tick(float DeltaTime) override;
	virtual void BeginPlay() override;
	virtual void SetupPlayerInputComponent(UEnhancedInputComponent* Input);

	// ─── JSON round-trip — the wire format of the entire pipeline ─────────────
	UFUNCTION(BlueprintCallable, Category="BlurFocusSim|JSON")
	void    ApplyJSONState(const FString& JSONString);

	UFUNCTION(BlueprintCallable, Category="BlurFocusSim|JSON")
	FString DumpJSONState() const;

	// ─── Live interaction (called from input or external systems) ─────────────
	UFUNCTION(BlueprintCallable, Category="BlurFocusSim|Interaction")
	void    OnImpact(FVector HitWorldPos, float Strength);

	UFUNCTION(BlueprintCallable, Category="BlurFocusSim|Interaction")
	void    ResetSimulation();

	// ─── Slider hooks (UMG can call these directly) ───────────────────────────
	UFUNCTION(BlueprintCallable, Category="BlurFocusSim|Live") void SetAmplitude(float V) { Amplitude = V; }
	UFUNCTION(BlueprintCallable, Category="BlurFocusSim|Live") void SetFrequency(float V) { Frequency = V; }
	UFUNCTION(BlueprintCallable, Category="BlurFocusSim|Live") void SetWaveSpeed(float V) { WaveSpeed = V; }
	UFUNCTION(BlueprintCallable, Category="BlurFocusSim|Live") void SetDamping(float V)   { Damping   = FMath::Clamp(V, 0.001f, 1.0f); }
	UFUNCTION(BlueprintCallable, Category="BlurFocusSim|Live") void ApplyCrystalNeonTennisStyle();

protected:
	// ─── Components ───────────────────────────────────────────────────────────
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Components")
	TObjectPtr<USceneComponent> RootScene;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Components")
	TObjectPtr<UStaticMeshComponent> SphereMesh;

	// ─── Data bindings (set in Blueprint defaults) ────────────────────────────
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BlurFocusSim|Bindings")
	TObjectPtr<UMaterialParameterCollection> MPC_Sim;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BlurFocusSim|Bindings")
	TObjectPtr<UDataTable> WaveDataTable;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BlurFocusSim|Bindings")
	TObjectPtr<UCurveFloat> WaveProfileCurve;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BlurFocusSim|Bindings")
	TObjectPtr<UCurveFloat> FresnelRampCurve;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BlurFocusSim|Bindings")
	TObjectPtr<UMediaPlayer> BaseMediaPlayer;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BlurFocusSim|Bindings")
	TObjectPtr<UMediaTexture> BaseMediaTexture;

	// ─── Input ────────────────────────────────────────────────────────────────
	UPROPERTY(EditAnywhere, Category="BlurFocusSim|Input") TObjectPtr<UInputMappingContext> IMC_Sim;
	UPROPERTY(EditAnywhere, Category="BlurFocusSim|Input") TObjectPtr<UInputAction> IA_Orbit;
	UPROPERTY(EditAnywhere, Category="BlurFocusSim|Input") TObjectPtr<UInputAction> IA_Zoom;
	UPROPERTY(EditAnywhere, Category="BlurFocusSim|Input") TObjectPtr<UInputAction> IA_Impact;
	UPROPERTY(EditAnywhere, Category="BlurFocusSim|Input") TObjectPtr<UInputAction> IA_WaveSpeed;
	UPROPERTY(EditAnywhere, Category="BlurFocusSim|Input") TObjectPtr<UInputAction> IA_Reset;

	// ─── Physics parameters (mirrors JSON schema · physics block) ─────────────
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BlurFocusSim|Physics", meta=(ClampMin="0.0", ClampMax="5.0"))  float Amplitude       = 0.8f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BlurFocusSim|Physics", meta=(ClampMin="0.1", ClampMax="10.0")) float Frequency       = 2.1f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BlurFocusSim|Physics", meta=(ClampMin="0.0", ClampMax="5.0"))  float WaveSpeed       = 1.4f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BlurFocusSim|Physics", meta=(ClampMin="0.001",ClampMax="1.0")) float Damping         = 0.6f;

	// ─── Material parameters (mirrors JSON schema · material block) ───────────
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BlurFocusSim|Material") FLinearColor BaseColor = FLinearColor(0.0f, 1.0f, 1.0f, 1.0f);
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BlurFocusSim|Material") FLinearColor AccentColor = FLinearColor(1.0f, 0.33f, 0.18f, 1.0f);
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BlurFocusSim|Material") float        EmissiveIntensity = 15.0f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BlurFocusSim|Material") float        FresnelPower      = 2.5f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BlurFocusSim|Material", meta=(ClampMin="0.0", ClampMax="1.0")) float CrystalWhiteness = 0.98f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BlurFocusSim|Material", meta=(ClampMin="0.0", ClampMax="1.0")) float GlassCoat = 0.9f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BlurFocusSim|Material", meta=(ClampMin="0.0", ClampMax="5.0")) float NeonFuzz = 2.4f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BlurFocusSim|Material", meta=(ClampMin="0.0", ClampMax="5.0")) float VolumetricFogDensity = 1.35f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BlurFocusSim|Material", meta=(ClampMin="0.0", ClampMax="5.0")) float RubberAccentStrength = 0.92f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BlurFocusSim|Material", meta=(ClampMin="0.0", ClampMax="5.0")) float WaveGlassDistortion = 0.7f;

	// ─── Tuning ───────────────────────────────────────────────────────────────
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BlurFocusSim|Tuning") bool  bUseBakedDataTable = true;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BlurFocusSim|Tuning") bool  bUseMediaTexture   = false;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BlurFocusSim|Tuning") float ImpactDecayRate    = 0.85f;

private:
	// ─── Runtime state ────────────────────────────────────────────────────────
	float     WaveTime         = 0.f;
	FVector2D ImpactUV         = FVector2D::ZeroVector;
	float     ImpactStrength   = 0.f;
	int32     CurrentFrameIdx  = 0;

	UPROPERTY(Transient) TObjectPtr<UMaterialParameterCollectionInstance> MPCInst;

	// ─── Internal helpers ─────────────────────────────────────────────────────
	void PushMPCParameters(float DeltaTime);
	void SampleBakedFrame();
	FVector2D ProjectWorldToUV(FVector WorldPos) const;

	// Enhanced Input handlers
	void HandleOrbit(const FInputActionValue& Value);
	void HandleZoom(const FInputActionValue& Value);
	void HandleImpact(const FInputActionValue& Value);
	void HandleWaveSpeed(const FInputActionValue& Value);
	void HandleReset(const FInputActionValue& Value);
};
