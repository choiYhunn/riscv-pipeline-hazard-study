# RISC-V 파이프라인 해저드 스터디 (컴퓨터구조 HW1)

> **Forwarding unit이 없는 5-stage 파이프라인**(Ripes 시뮬레이터)에서 GCD 루프의 RAW·control hazard를 찾고, 명령어 재배치(instruction scheduling)만으로 stall을 줄였습니다. **명령어 수는 61개 그대로, 121 → 115 cycles**입니다. 모든 수치는 Ripes **시뮬레이션** 결과이며 실제 CPU 측정이 아닙니다.

| 항목 | 내용 |
|---|---|
| 환경 | Ripes, RV32IM, 5-stage pipeline, **forwarding 없음**(hazard detection·stall 있음) |
| Q1 결과 | **121 → 115 cycles**, retired instructions 61 → 61, CPI 1.98 → 1.89 |
| Q1 방법 | 루프당 RAW stall 6 → 4 (재배치), 루프 3회 반복 → 6 cycles 감소 |
| Q2 | selection sort skeleton의 빈칸 3개 작성, load-use 간격 확보 |
| 근거 | 제출 당시 Ripes stage table·execution info 화면 ([`evidence/`](evidence)) |

> **정정 (2026-10-23):** 이 저장소의 첫 버전은 “forwarding 5-stage, 121 → 118 cycles”로 적혀 있었습니다. 제출 보고서는 forwarding unit이 **없는** 환경을 명시하고, 아래 Ripes 화면은 **121 → 115**를 보여 줍니다. 118은 제출 코드나 Ripes 화면으로 확인되지 않는 값이어서 삭제했습니다.

## Q1 — GCD 루프의 hazard와 재배치

### 왜 stall이 생기는가

Forwarding이 없으면 앞 명령어의 결과는 WB 단계에서 register file에 써진 뒤에야 다음 명령어의 ID 단계에서 읽힙니다. 이 환경에서 바로 다음 명령어가 그 값을 쓰면 2 cycle, 한 칸 떨어져 있으면 1 cycle을 기다립니다. 루프의 `beq`와 `j`는 분기가 확정되기 전에 가져온 명령어를 버려야 하므로(flush) control hazard를 만듭니다.

### 원본 루프 → 재배치 루프

원본 순서는 [제출 stage table](evidence/q1_original_stage_table.png)에 그대로 보입니다(Ripes는 `mv`를 `addi rd, rs, 0`으로 표시).

```asm
# Original                         # stall      # Optimized (q1_gcd/gcd_optimized.s)  # stall
loop: beq  a1, t0, done                          loop: beq  a1, t0, done
      div  t1, a0, a1                                  div  t1, a0, a1
      mul  t2, t1, a1   # t1  ->   2                    addi s2, s2, 1        # 빈 슬롯 채움
      sub  t3, a0, t2   # t2  ->   2                    mul  t2, t1, a1       # t1 -> 1
      add  s3, s3, t3   # t3  ->   2                    sub  t3, a0, t2       # t2 -> 2 (채울 명령 없음)
      addi s2, s2, 1                                    mv   a0, a1           # a0 마지막 사용 뒤로 이동
      mv   a0, a1                                       add  s3, s3, t3       # t3 -> 1
      mv   a1, t3                                       mv   a1, t3
      j    loop                                         j    loop
#                       루프당 6                                                 루프당 4
```

- `addi s2, s2, 1`(반복 횟수)은 결과에 영향이 없으므로 `div`–`mul` 사이로 옮겨 stall 1개를 채웠습니다.
- `mv a0, a1`은 `a0`의 마지막 읽기(`sub`) 직후로 옮겨 `sub`–`add` 사이 stall 1개를 채웠습니다.
- `mul`–`sub` 사이에는 옮길 수 있는 독립 명령어가 없어 2 stall이 남습니다.

### 결과 (Ripes, simulated)

| | Original | Optimized |
|---|---:|---:|
| Cycles | 121 | **115** |
| Instructions retired | 61 | 61 |
| CPI | 1.98 | 1.89 |
| 루프당 RAW stall | 6 | 4 |

GCD(48, 18)에서 루프 본문은 3회 실행되므로 2 stall × 3 = 6 cycles가 줄어 121 → 115가 됩니다. 명령어 수가 같으므로 차이는 모두 stall에서 나옵니다.

근거 화면: [원본 stage table](evidence/q1_original_stage_table.png) · [원본 execution info](evidence/q1_original_execution_info.png) · [재배치 stage table](evidence/q1_optimized_stage_table.png) · [재배치 execution info](evidence/q1_optimized_execution_info.png)

## Q2 — Selection sort 빈칸 작성 ([`q2_selection_sort/solution.s`](q2_selection_sort/solution.s))

바깥/안쪽 루프와 출력 루틴은 수업 제공 skeleton이고, `blank (1)~(3)`이 제가 작성한 부분입니다.

- **blank (1):** `min_idx = i`, `Array[min_idx]`를 레지스터(t2)에 캐시, `&Array[j]` 포인터를 미리 계산합니다.
- **blank (2):** 매 반복 인덱스 곱셈 대신 포인터를 4바이트씩 전진시킵니다. `addi t3, t3, 4`를 `lw t4`와 그 값을 쓰는 `slt` 사이에 두어, forwarding이 없는 환경의 load-use stall을 1 cycle 줄였습니다.
- **blank (3):** `Array[i]`와 최솟값을 메모리 store로 교환하고, 의존성 없는 `sw`를 사이에 두어 load 직후 사용을 피했습니다.

실행 결과: [`Selection Sorted: 2 4 7 12 16 23 33 38 45 56`, exit code 0](evidence/q2_console_sorted.png). Q2는 정렬 정확성만 확인했고 cycle 비교는 하지 않았습니다.

> `solution.s`의 명령어는 제출본과 같습니다. 원본 파일의 한글 주석이 인코딩 손상 상태여서 같은 의미의 주석을 UTF-8로 다시 적었습니다.

## 실행 방법

1. [Ripes](https://github.com/mortbopet/Ripes)에서 **forwarding unit이 없는 5-stage processor**와 RV32IM(`div`, `mul` 사용)을 선택합니다.
2. `q1_gcd/gcd_optimized.s`를 불러와 실행하고 execution info의 cycles·instructions를 확인합니다.
3. 원본과 비교하려면 위 표의 Original 순서로 루프 본문만 바꿔 실행합니다.

Ripes 버전이나 processor 모델이 다르면 cycle 수가 달라질 수 있습니다. 제출 당시 Ripes 버전은 기록하지 않았습니다.

## 한계

- 시뮬레이터 cycle 수이며 실제 하드웨어 측정이 아닙니다. 캐시·메모리 지연은 모델에 없습니다.
- 다른 설정(예: forwarding 포함)의 결과는 측정하지 않았고 이 표와 섞지 않습니다.
- 원본 GCD 코드와 Q2 skeleton은 수업 제공 자료라 별도 파일로 싣지 않았습니다. 제출 보고서(이름·학번 포함)도 싣지 않았습니다.
- 소프트웨어 license는 선정하지 않았습니다(All rights reserved).

## 구성

```text
.
├─ q1_gcd/gcd_optimized.s          # 재배치한 GCD (제출본과 동일)
├─ q2_selection_sort/solution.s    # skeleton + blank (1)~(3) 작성분
└─ evidence/                       # 제출 당시 Ripes 화면 (stage table, execution info, console)
```

---

## English summary

Computer Architecture HW1 on the Ripes simulator, using a **five-stage RV32IM pipeline without a forwarding unit**. In the GCD loop, each RAW dependency between adjacent instructions costs two stall cycles. Reordering independent instructions (`addi s2` into the `div`→`mul` gap, `mv a0, a1` after `a0`'s last read) cut loop stalls from 6 to 4 per iteration; with three loop iterations for GCD(48, 18), the program went from **121 to 115 cycles with the same 61 retired instructions** (CPI 1.98 → 1.89). Q2 fills the three blanks of a provided selection-sort skeleton, spacing a load from its first use. All numbers are simulator results; the submission-time Ripes screenshots are in [`evidence/`](evidence). **Correction (2026-10-23):** an earlier version of this README said “forwarding, 121 → 118 cycles”; neither the forwarding setting nor 118 is supported by the submitted report or the Ripes screenshots.
