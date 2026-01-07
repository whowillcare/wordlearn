
import wave
import math
import struct

def generate_beep(filename, duration=0.2, frequency=440.0):
    sample_rate = 44100
    n_frames = int(duration * sample_rate)
    
    with wave.open(filename, 'w') as obj:
        obj.setnchannels(1) # mono
        obj.setsampwidth(2) # 2 bytes per sample
        obj.setframerate(sample_rate)
        
        data = []
        for i in range(n_frames):
            value = int(32767.0 * 0.5 * math.sin(2.0 * math.pi * frequency * i / sample_rate))
            data.append(struct.pack('<h', value))
            
        obj.writeframes(b''.join(data))
    print(f"Generated {filename}")

# Generate distinct sounds
generate_beep('assets/sounds/error.wav', 0.2, 200.0)   # Low pitch
generate_beep('assets/sounds/fail.wav', 0.4, 150.0)    # Lower pitch
generate_beep('assets/sounds/success.wav', 0.3, 800.0) # High pitch
