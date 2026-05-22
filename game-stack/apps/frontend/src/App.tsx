import React from 'react';
import { Canvas } from '@react-three/fiber';
import { OrbitControls, Sky } from '@react-three/drei';
import { Physics, RigidBody } from '@react-three/rapier';

export default function App() {
  return (
    <Canvas shadows camera={{ position: [0, 5, 10], fov: 50 }}>
      <Sky sunPosition={[100, 20, 100]} />
      <ambientLight intensity={0.3} />
      <directionalLight castShadow position={[10, 10, 10]} intensity={1.5} />
      
      <Physics>
        {/* Dynamic dropping object */}
        <RigidBody position={[0, 5, 0]} colliders="cuboid">
          <mesh castShadow>
            <boxGeometry args={[1, 1, 1]} />
            <meshStandardMaterial color="hotpink" />
          </mesh>
        </RigidBody>

        {/* Static Ground */}
        <RigidBody type="fixed" colliders="cuboid">
          <mesh receiveShadow position={[0, -1, 0]}>
            <boxGeometry args={[20, 2, 20]} />
            <meshStandardMaterial color="lightgreen" />
          </mesh>
        </RigidBody>
      </Physics>

      <OrbitControls makeDefault />
    </Canvas>
  );
}
