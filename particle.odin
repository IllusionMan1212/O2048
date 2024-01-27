package main

import "core:math/rand"
import "core:time"

import "zephr"

Particle :: struct {
    pos: zephr.Vec2,
    vel: zephr.Vec2,
    color: zephr.Color,
    size: f32,
    life: time.Duration,
}

ParticleEmitter :: struct {
    pos: zephr.Vec2,
    particles: [dynamic]Particle,
    duration: time.Duration,
    spawn_rate: u32,
}

@private
last_emitted_particle_idx: int = 0
// restricts emission rate to 60fps
@private
particle_time: time.Duration = 0

@private
update_particles :: proc(delta_t: time.Duration, particles: ^[dynamic]Particle, start_pos: zephr.Vec2) {
    delta_t_f := cast(f32)time.duration_seconds(delta_t)

    for p in particles {
        p.life -= delta_t
        if p.life <= 0 {
            continue
        }

        // NOTE: fades faster on higher framerates. don't feel like fixing it
        p.color.a -= 1
        p.size -= delta_t_f
        p.vel.x += (p.pos.x + p.vel.x / 7) * delta_t_f
        p.vel.y -= (p.pos.y + p.vel.y / 7) * delta_t_f
        p.pos += p.vel * -delta_t_f
    }
}

@private
find_first_dead_particle :: proc(particles: [dynamic]Particle) -> int {
    // search from last emitted particle, should return almost immediately 
    for i in last_emitted_particle_idx..<cap(particles) {
        if particles[i].life <= 0 {
            last_emitted_particle_idx = i
            return i
        }
    }

    // else do linear search
    for p, i in particles {
        if p.life <= 0 {
            return i
        }
    }

    // overwrite first particle if all are alive
    last_emitted_particle_idx = 0
    return 0
}

update_emitter :: proc(delta_t: time.Duration, emitter: ^ParticleEmitter) {
    if emitter.duration > 0 {
        emitter.duration -= delta_t
        if emitter.duration <= 0 {
            return
        }

        particle_time += delta_t

        for particle_time >= time.Millisecond * 16 {
            for i in 0..<emitter.spawn_rate {
                random := cast(f32)(rand.int_max(100) - 50)
                offset := cast(f32)rand.int_max(100) - 50
                rand_velocity := zephr.Vec2{rand.float32_range(-500.0, 500.0) * random / 20, -rand.float32_range(-500.0, 500.0) * random / 20}
                found_dead_particle_idx := find_first_dead_particle(emitter.particles)
                assign_at(&emitter.particles, found_dead_particle_idx, Particle{
                    pos = emitter.pos,
                    vel = rand_velocity,
                    color = zephr.COLOR_WHITE,
                    size = 1,
                    life = time.Millisecond * 500,
                })
            }
            particle_time -= time.Millisecond * 16
        }
    }

    update_particles(delta_t, &emitter.particles, emitter.pos)
}

emitter_start :: proc(emitter: ^ParticleEmitter, capacity: int, pos: zephr.Vec2, duration: time.Duration, spawn_rate: u32 = 3) {
    // Should happen in an init function but this works too so idc
    // Valgrind says we leak here but I don't think so because we "delete()" the memory
    // when calling "reset_game()"
    if emitter.particles != nil {
        delete(emitter.particles)
    }

    emitter.particles = make([dynamic]Particle, capacity)
    emitter.pos = pos
    emitter.duration = duration
    emitter.spawn_rate = spawn_rate
}
