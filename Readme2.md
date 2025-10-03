# Windows 11 브라우저 아티팩트 포렌식 분석

이 문서는 The Sleuth Kit (TSK) 기반으로 **Windows 11** 가상 환경에서 확보한 디스크 이미지(`raw`)를 분석하고, 주요 **브라우저 아티팩트**를 추출 및 초기 분석하는 포렌식 실험 기록 및 워크플로우를 정리합니다.

-----

## 🔍 1. 실험 목표 및 환경 설정

| 구분 | 내용 | 비고 |
| :--- | :--- | :--- |
| **실험 목표** | Chrome, Edge, Firefox, Opera 등의 **브라우저 아티팩트** 조사 및 분석 | 사용자 행위 분석의 핵심 |
| **호스트 OS** | macOS | |
| **가상화 도구** | VMware Fusion 13.6.2 | |
| **게스트 OS** | Win11\_24H2\_Korean\_Arm64.iso (Windows 11) | |
| **주요 분석 도구** | The Sleuth Kit (TSK) | `mmls`, `fls`, `icat`, `istat` |

### 🛠️ 필수 전제 조건 (Prerequisites)

이 워크플로우를 실행하기 위해서는 다음 도구들이 macOS 또는 Linux **Bash 환경**에 설치되어 있어야 합니다.

  * **The Sleuth Kit (TSK)**: `mmls`, `fls`, `icat`, `istat`
  * **qemu-img**: 디스크 포맷 변환용
  * **쉘 유틸리티**: `sqlite3`, `file`, `strings`, `hexdump`, `grep`

-----

## 💾 2. 디스크 이미지 확보 및 전처리

| 단계 | 목적 | 실행 명령어 |
| :--- | :--- | :--- |
| **1. 디스크 이미징** | `vmdk`를 단일 디스크 포맷으로 변환 | \`\`\`bash
/Applications/VMware\\ Fusion.app/Contents/Library/vmware-vdiskmanager -r "Virtual Disk.vmdk" -t 0 single\_disk.vmdk

````|
| **2. 포맷 변환** | 분석 도구(TSK) 접근을 위한 **Raw 포맷** 변환 | ```bash
qemu-img convert -f vmdk "secondImaging.vmdk" -O raw secondImaging.raw
``` |

> **파일 명**: 이후 단계에서는 변환된 Raw 이미지 파일 이름을 **`secondImaging.raw`**로 가정합니다.

---

## 🔭 3. TSK 기반 파일 시스템 탐색 및 주요 경로 식별

### 3.1. 파티션 구조 확인 (`mmls`)

디스크 이미지의 **GPT (GUID Partition Table)** 구조를 확인하고, 메인 OS 데이터가 저장된 파티션의 **시작 섹터(Offset)**를 식별합니다.

```bash
mmls secondImaging.raw
````

**실행 결과 및 주요 정보:**

```
GUID Partition Table (EFI)
...
006:  002       0000239616   0132730879   0132491264   Basic data partition (NTFS, 메인 OS 파티션)
...
```

  * **메인 OS 파티션 시작 섹터 (Offset):** **`239616`**

### 3.2. 사용자 프로필 경로 탐색 (`fls`)

식별된 오프셋을 사용하여 파일 시스템의 루트 디렉토리와 사용자 프로필 디렉토리(`Users`)의 Inode를 추적합니다.

| 단계 | TSK 명령어 | 결과 목표 | 결과 Inode |
| :--- | :--- | :--- | :--- |
| **루트 디렉토리** | `fls -o 239616 secondImaging.raw` | `Users` 디렉토리 Inode 확인 | **`3442`** |
| **프로필 탐색** | `fls -o 239616 secondImaging.raw 3442` | 대상 사용자 프로필 Inode 확인 | **`189787-144-6`** (예시) |

  * **최종 타겟 Inode (프로필):** **`189787-144-6`**

-----

## 🚀 4. 아티팩트 자동 추출 및 분석 (Scripted Analysis)

TSK 명령어를 활용하여 **대상 사용자 프로필** 하위의 모든 \*\*정규 파일(Regular Files)\*\*을 재귀적으로 추출하고, 추출된 파일을 자동으로 분석하는 스크립트 기반 워크플로우입니다.

### 4.1. 아티팩트 추출 스크립트 (Placeholder)

#### `extract_profile_artifacts.sh`

지정된 **Raw 이미지**, **Offset**, **프로필 Inode**를 기반으로 `fls`와 `icat`을 재귀적으로 사용하여 모든 아티팩트를 **`extracted/`** 폴더에 저장합니다.

```bash
#!/bin/bash
# 추출 스크립트의 핵심 기능
# TARGET_IMAGE="secondImaging.raw"
# OFFSET="239616"
# ROOT_INODE="189787-144-6"
# fls -r -o $OFFSET $TARGET_IMAGE $ROOT_INODE | while read type inode name; do
#     # 정규 파일(r)만 icat으로 추출 로직
# done
```

### 4.2. 자동 초기 분석 스크립트 (Placeholder)

#### `analyze_extracted_artifacts.sh`

`extracted/` 폴더 내의 파일들을 대상으로 파일 타입에 따른 초기 포렌식 분석을 자동화합니다.

| 분석 영역 | 주요 기능 | 출력 경로 |
| :--- | :--- | :--- |
| **SQLite DB** | `sqlite3`로 **History, Cookies, Login Data** 등 브라우저 DB 확인 및 SQL 쿼리 실행 | `analysis_results/sqlite/` |
| **Strings** | `strings` 명령으로 파일 내 텍스트 추출 후, `openai\|chatgpt` 등 키워드 검색 | `analysis_results/strings/` |
| **요약/Hexdump** | `file` 명령으로 파일 타입 확인 및 `hexdump`로 파일 앞부분(1024 bytes) 생성 | `analysis_results/summary/`, `analysis_results/hexdump/` |

### 📂 분석 결과 디렉토리 구조

```
analysis_results/
├── sqlite/             # SQLite DB 스키마 및 쿼리 결과 (CSV)
├── strings/            # Strings 추출 및 키워드 검색 결과
├── hexdump/            # 각 파일의 앞부분 Hexdump
└── summary/            # 파일 타입 요약 및 간단 정보
```

-----

## (미구현) 5. 고급 포렌식 심화 분석 (Advanced Analysis)

초기 분석에서 발견된 암호화된 데이터나 LevelDB 기반의 아티팩트에 접근하기 위한 심화 단계입니다.

### 5.1. LevelDB/IndexedDB 분석 🔑

  * **목표**: 최신 브라우저의 IndexedDB에 저장된 **세션 기록, 웹 앱 데이터, 상세 대화 내용**(`chat.openai.com` 등)을 복원합니다. 이 데이터는 `.ldb`, `.log` 파일 포맷으로 존재합니다.
  * **권장 도구**: Python **`plyvel`** 라이브러리 등 LevelDB 파싱이 가능한 전용 도구를 사용해 정확한 **키-값 쌍**을 추출합니다.

### 5.2. DPAPI 암호화 데이터 복호화 🔒

  * **목표**: 브라우저의 `Login Data` 및 `Cookies` 파일 내의 **암호화된 비밀번호**나 **로그인 토큰**을 \*\*Windows DPAPI(Data Protection API)\*\*를 통해 평문으로 복원합니다.
  * **필요 사항**: 복호화를 위해서는 해당 사용자 계정의 **DPAPI 마스터 키** 또는 관련 시스템 파일(예: 사용자 암호 해시)이 필요하며, 이에 대한 전문적인 복호화 지식과 도구가 요구됩니다.

-----

## 🛠️ 스크립트 사용 가이드 (4번: 아티팩트 자동 추출 및 분석 (Scripted Analysis))

1.  **실행 권한 부여:**
    ```bash
    chmod +x extract_profile_artifacts.sh
    chmod +x analyze_extracted_artifacts.sh
    ```
2.  **아티팩트 추출:** (이미지 크기에 따라 시간이 소요될 수 있습니다.)
    ```bash
    ./extract_profile_artifacts.sh
    ```
3.  **초기 분석 실행:**
    ```bash
    ./analyze_extracted_artifacts.sh
    ```
4.  **결과 확인:** `analysis_results/` 폴더 내의 각 하위 폴더에서 브라우저 기록, 키워드 검색 결과 등을 확인합니다.