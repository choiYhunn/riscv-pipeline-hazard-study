# RISC-V 파이프라인 해저드 스터디 (컴퓨터구조 HW1)

> Ripes RISC-V 시뮬레이터(Forwarding 있는 5-stage pipeline)에서 두 과제를 다뤘습니다: (Q1) GCD 코드의 **data/control hazard 분석과 instruction scheduling 최적화**, (Q2) selection sort의 **빈칸 완성과 load-use hazard를 고려한 명령어 배치**. 수업 과제로 직접 작성한 어셈블리와 분석이며, 수치는 **Ripes 시뮬레이터 cycle count**입니다(실제 하드웨어 측정 아님).

| 항목 | 내용 |
|---|---|
| 환경 | Ripes, RV32, forwarding 포함 5-stage pipeline |
| Q1 | GCD — RAW/Control hazard 분석 → scheduling으로 stall 은닉 |
| Q1 결과 | **121 → 118 cycles** (Ripes, original → optimized) |
| Q2 | Selection sort — 제공 skeleton의 3개 blank 완성 + load-use 간격 배치 |
| 공개 | 본인 작성 어셈블리만. 제공 skeleton·보고서(개인정보 포함)는 미포함 |

## Q1 — GCD hazard 분석과 최적화 ([`q1_gcd/gcd_optimized.s`](q1_gcd/gcd_optimized.s))

주어진 GCD 코드를 forwarding 5-stage 파이프라인에서 분석했습니다.

- **Data hazard (RAW):** `div t1,a0,a1` → `mul t2,t1,a1` → `sub t3,a0,t2`의 연쇄 의존. forwarding으로도 긴 연산(div/mul) 뒤에는 stall이 생깁니다.
- **Control hazard:** 루프의 `beq`/`j`에서 분기 결과 확정 전 fetch된 명령어 flush.

**최적화 — instruction scheduling (latency hiding):** 결과에 영향을 주지 않는 독립 명령어(`addi s2,s2,1`, `mv a0,a1`, `add s3,s3,t3`)를 `div`/`mul`/`sub` 사이의 stall 슬롯으로 옮겨 지연을 가립니다. 공개한 `gcd_optimized.s`가 이 스케줄된 버전이며, 주석에 어떤 간격을 벌렸는지 적어 두었습니다.

| | Original | Optimized |
|---|---:|---:|
| Ripes total cycle | 121 | **118** |

> 원본(미최적화) 코드는 수업 제공 코드라 별도 파일로 포함하지 않고, 위 표와 설명으로 전후를 기록합니다. stage table 스크린샷은 개인정보가 있는 제출 보고서에만 있어 포함하지 않았습니다.

## Q2 — Selection sort 완성 ([`q2_selection_sort/solution.s`](q2_selection_sort/solution.s))

제공된 selection sort skeleton에는 3개의 blank가 있었고, 그 부분을 채웠습니다. 바깥 루프/안쪽 루프/출력 루틴의 뼈대는 제공 skeleton이며, 아래 3개 블록이 제가 작성한 부분입니다.

- **blank (1):** `min_idx = i` 초기화, `Array[min_idx]`를 min 캐시(t2)로 로드, `&Array[j]` 선계산.
- **blank (2):** `Array[j]` 로드 후, 다음 포인터를 **먼저** 증가시켜 로드-사용 간격을 벌림(load-use hazard 완화).
- **blank (3):** 최솟값과 `Array[i]`를 메모리 store로 swap.

> `solution.s`의 명령어는 제 제출본과 동일하지만, 원본 파일의 한글 주석이 인코딩 손상(깨짐) 상태라 **같은 의미의 주석을 UTF-8로 다시 작성**했습니다. 명령어 자체는 바꾸지 않았습니다.

## 한계 / 공개 범위

- cycle 수치는 Ripes 시뮬레이터 결과이며 실제 CPU 측정이 아닙니다.
- 특정 포워딩/해저드 유닛 구현(과제 환경) 가정에 따른 값입니다.
- 수업 제공 skeleton 원본, 제출 보고서(이름·학번 포함), 채점 기록, 타인 제출물은 포함하지 않습니다. 소프트웨어 license는 선정하지 않았습니다(All rights reserved).

---

## English summary

Computer-architecture HW1 on the Ripes RISC-V simulator (RV32, 5-stage pipeline with forwarding). **Q1 (GCD):** analyzed RAW data hazards (`div`→`mul`→`sub` dependency chain) and control hazards, then applied **instruction scheduling** — moving independent instructions into stall slots to hide latency — improving the Ripes cycle count from **121 to 118** ([`q1_gcd/gcd_optimized.s`](q1_gcd/gcd_optimized.s)). **Q2 (selection sort):** completed the three blanks of a provided skeleton, including spacing a load from its use to ease a load-use hazard ([`q2_selection_sort/solution.s`](q2_selection_sort/solution.s)). Cycle counts are simulator results, not hardware measurements. The instructor-provided skeleton, the PII-bearing submission report, grading records, and other students' files are not included; Q2 comments were re-typed into UTF-8 because the original Korean comments were encoding-corrupted (instructions unchanged). No license granted (all rights reserved).
