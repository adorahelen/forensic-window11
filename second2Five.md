#### 2-5. Local 디렉토리 탐색
Users/사용자프로필/AppData/Local
```bash
# Local 디렉토리 내용 확인 (inode: 82123-144-5)
fls -o 239616 secondImaging.raw 82123-144-5
```

Users/사용자프로필/AppData/Local/Google/Chrome/User Data/Default
=> ReadMe.md 참조 

=============================/Microsoft/Edge/User Data/Default
fls -o 239616 secondImaging.raw 82125-144-6
fls -o 239616 secondImaging.raw 82997-144-1
fls -o 239616 secondImaging.raw 82998-144-7
fls -o 239616 secondImaging.raw 114938-144-6
r/r 114959-128-3:	History

# 방문기록 (History)
icat -o 239616 secondImaging.raw 114959-128-3 > History

# 로그인 데이터
icat -o 239616 secondImaging.raw 114975-128-4 > "Login Data"

# 자동완성 및 폼 데이터
icat -o 239616 secondImaging.raw 130387-128-4 > "Web Data"

[여기까지가 엣지]

Users/사용자프로필/AppData/Local/Mozilla/Firefox/Profiles/mtt6gxcy.default-release/데이터베이스 파일 없음 
fls -o 239616 secondImaging.raw
229641-144-1
229642-144-1
229372-144-1
229373-144-6

// 로밍 경로부터 다시 
82102-144-1
229629-144-1
229630-144-5
229368-144-1
229369-144-10

Users/사용자프로필/AppData/Roaming/Mozilla/Firefox/Profiles/mtt6gxcy.default-release/places.sqlite
=> 역추적 아래의 해당 경로에 있었으며, 이유는 Local에 두지 않음으로 물리적 환경 구속 벗어남
 fls -pr -o 239616 secondImaging.raw | grep 229450
r/r 229450-128-6:	Users/cisla/AppData/Roaming/Mozilla/Firefox/Profiles/mtt6gxcy.default-release/places.sqlite

(낚시 당한 흔적)
fls -o 239616 secondImaging.raw 229373-144-6
r/r 234656-128-1:	activity-stream.contile.json
r/r 229906-128-1:	activity-stream.discovery_stream.json
r/r 229715-128-1:	activity-stream.inferred_personalization_feed.json
r/r 235618-128-1:	activity-stream.weather_feed.json
d/d 229391-144-7:	cache2
d/d 229778-144-6:	jumpListCache
d/d 235268-144-7:	safebrowsing
d/d 229721-144-1:	settings
d/d 229390-144-8:	startupCache
d/d 229419-144-1:	thumbnails

=> 그랩으로 조회하는 방법
fls -r -o 239616 secondImaging.raw | grep places.sqlite
++++++++ r/r 229450-128-6:	places.sqlite
++++++++ r/r 229457-128-6:	places.sqlite-shm
++++++++ r/r 229456-128-6:	places.sqlite-wal

[여기까지가 파이어폭스]

=============================/Naver/Naver Whale/User Data/Default
230720-144-1
230721-144-1
230722-144-6
230739-144-6

icat -o 239616 secondImaging.raw 231123-128-4 > Web_Data
icat -o 239616 secondImaging.raw 231126-128-4 > Web_Data-journal
icat -o 239616 secondImaging.raw 231127-128-4 > Login_Data
icat -o 239616 secondImaging.raw 231128-128-4 > Login_Data-journal
icat -o 239616 secondImaging.raw 230755-128-3 > History
icat -o 239616 secondImaging.raw 230756-128-4 > History-journal
icat -o 239616 secondImaging.raw 230910-128-4 > Top_Sites
icat -o 239616 secondImaging.raw 230911-128-4 > Top_Sites-journal
icat -o 239616 secondImaging.raw 230770-128-3 > Favicons
icat -o 239616 secondImaging.raw 230773-128-4 > Favicons-journal
icat -o 239616 secondImaging.raw 231271-128-4 > Network_Action_Predictor
icat -o 239616 secondImaging.raw 231272-128-4 > Network_Action_Predictor-journal
icat -o 239616 secondImaging.raw 231129-128-4 > Account_Web_Data



========Users/사용자프로필/AppData/Roaming/Opera Software/Opera Stable/Default
82102-144-1 
231601-144-1
231660-144-6
232141-144-6

[로컬 아래 경로에 있는것은 캐시]
232154-144-1
232155-144-1
232156-144-1

[해당 경로에서 쓸만한 데이터베이스 파일들 추출 명령어]
icat -o 239616 secondImaging.raw 232153-128-3 > History
icat -o 239616 secondImaging.raw 232174-128-4 > History-journal
icat -o 239616 secondImaging.raw 232219-128-4 > "Login Data"
icat -o 239616 secondImaging.raw 232222-128-1 > "Login Data-journal"
icat -o 239616 secondImaging.raw 232220-128-4 > "Web Data"
icat -o 239616 secondImaging.raw 232226-128-4 > "Web Data-journal"
icat -o 239616 secondImaging.raw 232179-128-3 > Favicons
icat -o 239616 secondImaging.raw 232180-128-4 > Favicons-journal
icat -o 239616 secondImaging.raw 232604-128-4 > Bookmarks
icat -o 239616 secondImaging.raw 239239-128-4 > Preferences
icat -o 239616 secondImaging.raw 238912-128-4 > "Secure Preferences"
icat -o 239616 secondImaging.raw 232520-128-4 > Shortcuts
icat -o 239616 secondImaging.raw 232521-128-1 > Shortcuts-journal
icat -o 239616 secondImaging.raw 232516-128-4 > "Network Action Predictor"
icat -o 239616 secondImaging.raw 232517-128-4 > "Network Action Predictor-journal"
icat -o 239616 secondImaging.raw 232511-128-3 > DIPS
icat -o 239616 secondImaging.raw 232507-128-3 > DIPS-wal