## 윈도우 11 포렌식 실험 요약

아티팩트를 조사하기 위해 파일 시스템을 탐색하는 과정

-----

## 실험 환경

  * **운영 체제:** macOS
  * **사용 도구:** Sleuthkit
  * **가상 환경:** VMware Fusion (버전: `VMware-Fusion-13.6.2-24409261_universal.dmg`)
  * **게스트 OS:** Windows 11 (버전: `Win11_24H2_Korean_Arm64.iso`)
  * **조사 대상:** Chrome, Edge, Firefox, Opera 등의 브라우저 아티팩트

-----

## 실험 방법

1.  **이미징:** 가상 디스크 파일(`Virtual Disk.vmdk`)을 단일 모놀리식 스파스(`-t 0`) 형식의 다른 `.vmdk` 파일(`single_disk.vmdk`)로 복사합니다.
    ```bash
    /Applications/VMware\ Fusion.app/Contents/Library/vmware-vdiskmanager -r "Virtual Disk.vmdk" -t 0 single_disk.vmdk
    ```
2.  **포맷 변환:** `.vmdk` 파일을 Sleuthkit에서 분석하기 쉬운 **RAW** 이미지 파일로 변환합니다.
    ```bash
    qemu-img convert -f vmdk "secondImaging.vmdk" -O raw secondImaging.raw
    ```
3.  **파일 시스템 탐색:** Sleuthkit 도구(`fls`, `icat`, `istat`)를 이용해 파일 시스템 (inode 기반)을 탐색합니다.

-----

## Sleuthkit 명령어 분석 및 로그

### 1\. 파티션 시작 섹터 확인

파티션 구조를 확인하고, 파일 시스템 분석을 시작할 주 파티션의 \*\*시작 섹터(Offset Sector)\*\*를 찾습니다.

```bash
# 파티션 테이블 확인
mmls 해당파일.raw
```

**mmls 출력 (GUID Partition Table)**

```
GUID Partition Table (EFI)
Offset Sector: 0
Units are in 512-byte sectors

      Slot      Start        End          Length       Description
000:  Meta      0000000000   0000000000   0000000001   Safety Table
001:  -------   0000000000   0000002047   0000002048   Unallocated
002:  Meta      0000000001   0000000001   0000000001   GPT Header
003:  Meta      0000000002   0000000033   0000000032   Partition Table
004:  000       0000002048   0000206847   0000204800   Basic data partition
005:  001       0000206848   0000239615   0000032768   Microsoft reserved partition
006:  002       0000239616   0132730879   0132491264   Basic data partition  # <--- 주 NTFS 파티션 (시작 섹터: 239616)
007:  003       0132730880   0134213631   0001482752   
008:  -------   0134213632   0134217727   0000004096   Unallocated
```

> **주석:** 주 데이터 파티션(Basic data partition, 슬롯 006)의 시작 섹터는 **239616**입니다. 이후 모든 Sleuthkit 명령어는 이 섹터 오프셋(`-o 239616`)을 사용합니다.

-----

### 2\. Chrome 아티팩트 경로 탐색 (fls 사용)

#### 2-1. 루트 디렉토리 탐색

```bash
# 루트 디렉토리 목록 확인 (NTFS 파티션 오프셋 239616 적용)
fls -o 239616 secondImaging.raw
```

#### 2-2. Users 디렉토리 탐색

```bash
# Users 디렉토리 내용 확인 (inode: 3442-144-5)
fls -o 239616 secondImaging.raw 3442-144-5
```

#### 2-3. cisla 사용자 디렉토리 탐색

```bash
# cisla 사용자 디렉토리 내용 확인 (inode: 82084-144-5)
fls -o 239616 secondImaging.raw 82084-144-5
```

#### 2-4. AppData 디렉토리 탐색

```bash
# AppData 디렉토리 내용 확인 (inode: 82099-144-1)
fls -o 239616 secondImaging.raw 82099-144-1
```

#### 2-5. Local 디렉토리 탐색 & Romming 디렉토리에 있는 경우도 있음

```bash
# Local 디렉토리 내용 확인 (inode: 82123-144-5)
fls -o 239616 secondImaging.raw 82123-144-5
```


#### 2-6. Google 디렉토리 탐색

```bash
# Google 디렉토리 내용 확인 (inode: 189843-144-1)
fls -o 239616 secondImaging.raw 189843-144-1
```

#### 2-7. Chrome 디렉토리 탐색

```bash
# Chrome 디렉토리 내용 확인 (inode: 189844-144-1)
fls -o 239616 secondImaging.raw 189844-144-1
```

#### 2-8. User Data 디렉토리 탐색

```bash
# User Data 디렉토리 내용 확인 (inode: 189845-144-6)
fls -o 239616 secondImaging.raw 189845-144-6
```

#### 2-9. Default 사용자 프로필 디렉토리 탐색

```bash
# Default 프로필 디렉토리 내용 확인 (inode: 189787-144-6)
fls -o 239616 secondImaging.raw 189787-144-6
```

### 3\. 파일 추출 및 분석

#### 3-1. 파일 추출 (icat 사용)

찾아낸 핵심 아티팩트 파일들을 inode를 이용해 추출합니다. 예시로 **History** 파일을 추출하는 명령어입니다.

```bash
# History 파일 추출 (inode: 190179)
icat -o 239616 secondImaging.raw 190179 > History
```

> **주석:** `icat` 명령어는 지정된 inode(`190179`)에 해당하는 파일의 내용을 RAW 이미지(`secondImaging.raw`)에서 추출하여 `History`라는 이름의 파일로 저장합니다.

#### 3-2. 파일 분석

추출된 파일은 포렌식 분석 도구로 내용을 확인합니다.
=> 그냥 GUI 툴 쓰는게 정신 건강에 이로움 SQLite Browser 등 

```bash
# SQLite 데이터베이스 파일(History, Login Data, Web Data 등) 분석
sqlite3 History
# 파일 내용에서 문자열 추출 (삭제된 데이터 복구 등에 활용 가능)
strings History
# 파일의 16진수/ASCII 값 확인
hexdump -C History
```

> **주석:** Chrome 아티팩트 대부분은 **SQLite 데이터베이스(.db)** 형식으로 저장되어 있으므로, `sqlite3` 도구를 사용하여 데이터베이스 내부의 테이블 및 레코드를 직접 쿼리하여 분석합니다.