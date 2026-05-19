Fresh-context review — EMBEDDED C / C++ FIRMWARE mode.

Born from SIDKIT (Teensy 4.1, ARM Cortex-M7, 48 kHz audio DSP). Patterns
apply to any real-time embedded codebase — adapt the hardware specifics
for your platform.

**Focus areas (in priority order):**

1. **Audio / real-time safety** — `FASTRUN` on `update()` / `process()`,
   no heap (`new`/`malloc`/`vector::push_back`) in audio callbacks, no
   blocking calls (`delay`, `Serial.print`, SD reads) in ISRs, interrupt
   guards (`__disable_irq`/`__enable_irq`) around shared register writes.
2. **Module / interface contracts** — every virtual implemented, ctor
   doesn't allocate at static-init time, registration macro used,
   slot/voice ownership clear.
3. **CPU budget** — known-cost engines flagged against project budget
   (e.g. SIDKIT: 80 bits available, 20 reserved for system/display). One
   maxed slot must still fit.
4. **Hardware constraints** — sample rate matches USB-Audio class
   (48 kHz, never 44.1 or 22.05 on Teensy), pin assignments match PCB
   spec, SD-card startup delay respected, DMA priority sane.
5. **OLED / display wiring** — for projects with a GreyPage-style page
   system, walk the wiring checklist (header, draw, handleEncoder, enum,
   case statements). Missing one step is the #1 cause of pages that
   compile but never appear.
6. **SysEx / MIDI protocol** — 7-bit data byte mask (`& 0x7F`, not
   `& 0x07`), subsystem codes below 0x80, handler context (MIDI loop
   vs audio ISR), no heap in callback.
7. **Cross-translation-unit ODR** — heavy library headers (reSID,
   Plaits, etc.) confined to one TU; HIL/diagnostic shims use
   `extern "C"` to avoid mangling mismatches.
8. **Build flags** — required `-D` defines present (`USB_MIDI_AUDIO_SERIAL`,
   `AUDIO_SAMPLE_RATE_EXACT=48000`), unintended flag coupling flagged.

**Audit tools you can run** (project-specific, adapt to your tree):
- `pio run` (PlatformIO) — verify build still links
- `python3 SIDKIT-Health/sidkit-health folder:<src>` — 7 detectors
  (drift, lib_dependency, pin_conflicts, sample_rate, usb_audio,
  oled_design, test_coverage)
- `cd <test-rig> && pio run` — verify TESTS subdirs still build
- `grep -rn FASTRUN <src>` — confirm FASTRUN coverage on update() paths

**Output format:**

```
## Verdict: <SHIP | MERGE-WITH-FOLLOWUPS | NEEDS-CHANGES>

## Risk register

### HIGH (audio/real-time safety)
1. <summary> — `file:line` — mechanism — fix sketch.

### MEDIUM (correctness / hardware constraint)
...

### LOW (style, minor)
...

## Build/audit signals
- `pio run`: pass | fail (<key error>)
- `sidkit-health folder:src`: <score> / top 3 detectors
- `grep FASTRUN`: <coverage>

## Followups
- ...
```
