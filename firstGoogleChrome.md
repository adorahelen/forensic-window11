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

**루트 디렉토리 목록**

```
d/d 106119-144-1:	Documents and Settings
d/d 3319-144-6:	ProgramData
d/d 3442-144-5:	Users.    # <--- 특정 사용자 프로필 경로
r/r 4-128-1:	$AttrDef
r/r 8-128-2:	$BadClus
r/r 8-128-1:	$BadClus:$Bad
r/r 6-128-4:	$Bitmap
r/r 6-128-5:	$Bitmap:$SRAT
r/r 7-128-1:	$Boot
d/d 11-144-4:	$Extend
r/r 2-128-1:	$LogFile
r/r 0-128-6:	$MFT
r/r 1-128-1:	$MFTMirr
d/d 1173-144-1:	$Recycle.Bin
r/r 9-144-17:	$Secure:$SDH
r/r 9-144-16:	$Secure:$SII
r/r 9-128-18:	$Secure:$SDS
r/r 10-128-1:	$UpCase
r/r 10-128-4:	$UpCase:$Info
r/r 3-128-3:	$Volume
r/r 103375-128-1:	DumpStack.log.tmp
d/d 124786-144-1:	inetpub
d/d 181925-144-1:	OneDriveTemp
d/d 1174-144-1:	PerfLogs
d/d 1175-144-6:	Program Files
d/d 3096-144-6:	Program Files (x86)
d/d 106275-144-1:	Recovery
r/r 103376-128-1:	swapfile.sys
d/d 103340-144-6:	System Volume Information
d/d 3499-144-5:	Windows
V/V 240640:	$OrphanFiles
r/r 104155-128-1:	hiberfil.sys
r/r 103374-128-1:	pagefile.sys
```

#### 2-2. Users 디렉토리 탐색

```bash
# Users 디렉토리 내용 확인 (inode: 3442-144-5)
fls -o 239616 secondImaging.raw 3442-144-5
```

**Users 디렉토리 목록**

```
d/d 39563-144-1:    All Users
d/d 82084-144-5:    cisla           # <--- 특정 사용자 프로필 경로
d/d 3443-144-5: Default
d/d 38306-144-1:    Default User
r/r 38309-128-1:	desktop.ini
d/d 3491-144-5: Public
```

#### 2-3. cisla 사용자 디렉토리 탐색

```bash
# cisla 사용자 디렉토리 내용 확인 (inode: 82084-144-5)
fls -o 239616 secondImaging.raw 82084-144-5
```

**cisla 디렉토리 목록**

```
r/r 82201-128-1:	NTUSER.DAT{b2748d63-9624-11f0-bc7b-f5a8439e9a70}.TM.blf
d/d 82099-144-1:	AppData.  # <--- 특정 사용자 프로필 경로
d/d 82220-144-1:	Application Data
d/d 82960-144-1:	Contacts
d/d 82231-144-1:	Cookies
d/d 82097-144-1:	Desktop
d/d 82096-144-6:	Documents
d/d 82095-144-1:	Downloads
d/d 82094-144-1:	Favorites
d/d 82092-144-1:	Links
d/d 82228-144-1:	Local Settings
d/d 82091-144-1:	Music
d/d 82214-144-1:	My Documents
d/d 82221-144-1:	NetHood
r/r 82085-128-5:	NTUSER.DAT
r/r 82197-128-4:	ntuser.dat.LOG1
r/r 82198-128-4:	ntuser.dat.LOG2
r/r 82202-128-1:	NTUSER.DAT{b2748d63-9624-11f0-bc7b-f5a8439e9a70}.TMContainer00000000000000000001.regtrans-ms
r/r 82203-128-1:	NTUSER.DAT{b2748d63-9624-11f0-bc7b-f5a8439e9a70}.TMContainer00000000000000000002.regtrans-ms
r/r 82238-128-1:	ntuser.ini
d/d 187919-144-10:	OneDrive
d/r 187919-128-13:	OneDrive:${3D0CE612-FDEE-43f7-8ACA-957BEC0CCBA0}.SyncRootIdentity
d/d 82090-144-1:	Pictures
d/d 82222-144-1:	PrintHood
d/d 82223-144-1:	Recent
d/d 82088-144-1:	Saved Games
d/d 82971-144-5:	Searches
d/d 82224-144-1:	SendTo
d/d 82227-144-1:	Templates
d/d 82086-144-1:	Videos
d/d 82225-144-1:	시작 메뉴
```

#### 2-4. AppData 디렉토리 탐색

```bash
# AppData 디렉토리 내용 확인 (inode: 82099-144-1)
fls -o 239616 secondImaging.raw 82099-144-1
```

**AppData 디렉토리 목록**

```
d/d 82123-144-5:    Local           # <--- Local (브라우저 데이터는 보통 여기에 위치)
d/d 82237-144-1:    LocalLow
d/d 82102-144-1:    Roaming
```

#### 2-5. Local 디렉토리 탐색

```bash
# Local 디렉토리 내용 확인 (inode: 82123-144-5)
fls -o 239616 secondImaging.raw 82123-144-5
```

**Local 디렉토리 목록**

```
d/d 82229-144-1:	Application Data
d/d 66-144-1:	Comms
d/d 82550-144-6:	ConnectedDevicesPlatform
d/d 189843-144-1:	Google # <--- Google (Chrome 브라우저 경로)
d/d 82232-144-1:	History
d/d 82125-144-6:	Microsoft
d/d 82569-144-6:	Packages
d/d 114922-144-1:	PlaceholderTileLogoFolder
d/d 131198-144-1:	Publishers
d/d 82124-144-6:	Temp
d/d 82233-144-1:	Temporary Internet Files
d/d 82868-144-1:	VirtualStore
```

#### 2-6. Google 디렉토리 탐색

```bash
# Google 디렉토리 내용 확인 (inode: 189843-144-1)
fls -o 239616 secondImaging.raw 189843-144-1
```

**Google 디렉토리 목록**

```
d/d 189844-144-1:    Chrome          # <--- Chrome 브라우저 경로
```

#### 2-7. Chrome 디렉토리 탐색

```bash
# Chrome 디렉토리 내용 확인 (inode: 189844-144-1)
fls -o 239616 secondImaging.raw 189844-144-1
```

**Chrome 디렉토리 목록**

```
d/d 189845-144-6:    User Data       # <--- 사용자 프로필 데이터 경로
```

#### 2-8. User Data 디렉토리 탐색

```bash
# User Data 디렉토리 내용 확인 (inode: 189845-144-6)
fls -o 239616 secondImaging.raw 189845-144-6
```

**User Data 디렉토리 목록**
 
```
r/r 190199-128-1:	First Run
d/d 190208-144-1:	PrivacySandboxAttestationsPreloaded
d/d 190237-144-1:	AmountExtractionHeuristicRegexes
d/d 190233-144-1:	AutofillStates
d/d 226-144-6:	BrowserMetrics
r/r 2327-128-4:	BrowserMetrics-spare.pma
d/d 190223-144-1:	CertificateRevocation
d/d 190167-144-6:	component_crx_cache
d/d 190236-144-1:	CookieReadinessList
d/d 189846-144-1:	Crashpad
r/r 2163-128-4:	CrashpadMetrics-active.pma
d/d 190230-144-1:	Crowd Deny
d/d 189787-144-6:	Default.    # <--- 기본 사용자 프로필 (Default)
d/d 226944-144-1:	DeferredBrowserMetrics
r/r 190486-128-4:	en-US-10-1.bdic
d/d 190344-144-1:	extensions_crx_cache
d/d 190222-144-1:	FileTypePolicies
d/d 190239-144-1:	ProbabilisticRevealTokenRegistry
d/d 190214-144-1:	RecoveryImproved
d/d 190205-144-7:	Safe Browsing
d/d 190229-144-1:	SafetyTips
d/d 190176-144-1:	segmentation_platform
d/d 190170-144-1:	ShaderCache
d/d 190221-144-1:	SSLErrorAssistant
d/d 190217-144-1:	Subresource Filter
d/d 190234-144-1:	TpcdMetadata
d/d 190220-144-1:	TrustTokenKeyCommitments
r/r 189786-128-13:	Variations
d/d 190238-144-1:	WasmTtsEngine
d/d 190216-144-1:	WidevineCdm
d/d 190232-144-1:	ZxcvbnData
d/d 190433-144-1:	FirstPartySetsPreloaded
r/r 190531-128-4:	first_party_sets.db
r/r 190532-128-4:	first_party_sets.db-journal
d/d 190420-144-1:	GraphiteDawnCache
d/d 190414-144-1:	GrShaderCache
d/d 190231-144-1:	hyphen-data
r/r 190510-128-4:	ko-3-0.bdic
r/r 190435-128-7:	Last Browser
r/r 190169-128-8:	Last Version
r/r 187566-128-4:	Local State
r/r 2188-128-1:	lockfile
d/d 190225-144-1:	MEIPreload
d/d 190235-144-1:	OpenCookieDatabase
d/d 190219-144-1:	OptimizationHints
d/d 190921-144-6:	optimization_guide_model_store
d/d 190224-144-1:	OriginTrials
d/d 190226-144-1:	PKIMetadata
```

#### 2-9. Default 사용자 프로필 디렉토리 탐색

```bash
# Default 프로필 디렉토리 내용 확인 (inode: 189787-144-6)
fls -o 239616 secondImaging.raw 189787-144-6
```

**Default 디렉토리 목록** (브라우저 아티팩트 파일 포함)

```
r/r 190403-128-4:	Account Web Data
r/r 190404-128-4:	Account Web Data-journal
d/d 1723-144-1:	Accounts
r/r 190197-128-4:	Affiliation Database
r/r 190198-128-4:	Affiliation Database-journal
d/d 190490-144-1:	AutofillStrikeDatabase
d/d 190427-144-1:	blob_storage
r/r 2231-128-1:	BookmarkMergedSurfaceOrdering
r/r 190496-128-4:	BrowsingTopicsSiteData
r/r 190497-128-1:	BrowsingTopicsSiteData-journal
r/r 2244-128-4:	BrowsingTopicsState
r/r 29637-128-1:	passkey_enclave_state
d/d 190189-144-1:	PersistentOriginTrials
r/r 105979-128-4:	Preferences
r/r 190495-128-1:	PreferredApps
d/d 190206-144-6:	Safe Browsing Network
r/r 2189-128-4:	Secure Preferences
d/d 190262-144-6:	Segmentation Platform
r/r 190203-128-4:	ServerCertificate
r/r 190204-128-1:	ServerCertificate-journal
d/d 190354-144-1:	Service Worker
d/d 190451-144-6:	Session Storage
d/d 210611-144-5:	Sessions
d/d 190183-144-1:	Shared Dictionary
d/d 190243-144-1:	discount_infos_db
d/d 190431-144-1:	Download Service
d/d 190209-144-6:	Extension Rules
d/d 190264-144-6:	Extension Scripts
d/d 190348-144-6:	Extension State
d/d 190573-144-6:	Extensions
r/r 190212-128-3:	Favicons
r/r 190213-128-4:	Favicons-journal
d/d 189850-144-1:	Feature Engagement Tracker
d/d 190518-144-6:	GCM Store
r/r 1933-128-4:	Google Profile Picture.png
r/r 1937-128-4:	Google Profile.ico
d/d 190313-144-1:	GPUCache
r/r 190429-128-4:	heavy_ad_intervention_opt_out.db
r/r 190430-128-4:	heavy_ad_intervention_opt_out.db-journal
r/r 2225-128-1:	SharedStorage-wal
d/d 190332-144-6:	shared_proto_db
r/r 210613-128-4:	Shortcuts
r/r 210616-128-4:	Shortcuts-journal
d/d 190200-144-6:	Site Characteristics Database
d/d 190752-144-1:	Storage
d/d 190193-144-6:	Sync Data
r/r 190297-128-4:	Top Sites
r/r 190298-128-4:	Top Sites-journal
r/r 2227-128-1:	trusted_vault.pb
d/d 190437-144-1:	Web Applications
r/r 190395-128-4:	Web Data.     # <--- 자동 완성 데이터, 키워드 검색 등 (SQLite DB)
r/r 190396-128-4:	Web Data-journal
d/d 190345-144-1:	WebStorage
r/r 190179-128-3:	History.     # <--- 방문 기록, 다운로드 기록 등 (SQLite DB)
r/r 190192-128-4:	History-journal
d/d 27215-144-1:	IndexedDB
d/d 190743-144-1:	Local Extension Settings
d/d 190367-144-1:	Local Storage
r/r 190259-128-1:	LOCK
r/r 2217-128-1:	LOG
r/r 2179-128-1:	LOG.old
r/r 190397-128-4:	Login Data.   # <--- 저장된 비밀번호 (SQLite DB)
r/r 190398-128-4:	Login Data For Account
r/r 190400-128-4:	Login Data For Account-journal
r/r 190399-128-1:	Login Data-journal
r/r 227368-128-4:	MediaDeviceSalts
r/r 227370-128-4:	MediaDeviceSalts-journal
d/d 190184-144-5:	Network
r/r 190408-128-4:	Network Action Predictor
r/r 210614-128-4:	Network Action Predictor-journal
d/d 190487-144-6:	optimization_guide_hint_cache_store
d/d 190512-144-1:	BudgetDatabase
d/d 190180-144-1:	Cache
d/d 190246-144-1:	chrome_cart_db
d/d 190186-144-1:	ClientCertificates
d/d 190292-144-1:	Code Cache
d/d 190955-144-1:	Collaboration
d/d 190257-144-1:	commerce_subscription_db
r/r 27249-128-4:	Conversions
r/r 27250-128-4:	Conversions-journal
d/d 190949-144-1:	DataSharing
d/d 190326-144-1:	DawnGraphiteCache
d/d 190320-144-1:	DawnWebGPUCache
r/r 190159-128-3:	DIPS
r/r 2228-128-3:	DIPS-wal
d/d 190251-144-1:	discounts_db
d/d 190240-144-1:	parcel_tracking_db
r/r 190406-128-4:	SharedStorage
```

-----

### 3\. 파일 추출 및 분석

#### 3-1. 파일 추출 (icat 사용)

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

#### 3-2. 파일 분석

추출된 파일은 DB Browser for SQLite를 통해 수행 