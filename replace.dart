import 'dart:io';

void main() {
  var f = File('lib/main.dart');
  var text = f.readAsStringSync();

  var replacements = {
    "'설정 화면 열기'": "LocalizationService.get('tray_show')",
    "'시작프로그램 등록완료 (BridgeClip)'": "LocalizationService.get('tray_ready')",
    "'완전 종료'": "LocalizationService.get('tray_exit')",
    "const Text('클립보드에 복사되었습니다!', style: TextStyle(color: Colors.white))": "Text(LocalizationService.get('copied_toast'), style: const TextStyle(color: Colors.white))",
    "const Text('자동 삭제 타이머 ⏱️', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))": "Text(LocalizationService.get('timer_title'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))",
    "'기기 영구 보관'": "LocalizationService.get('timer_keep_forever')",
    "'1분 뒤 자동 삭제'": "LocalizationService.get('timer_1m')",
    "'10분 뒤 자동 삭제'": "LocalizationService.get('timer_10m')",
    "'1시간 뒤 자동 삭제'": "LocalizationService.get('timer_1h')",
    "'1일 뒤 자동 삭제'": "LocalizationService.get('timer_1d')",
    "const Text('닫기', style: TextStyle(color: Colors.white54))": "Text(LocalizationService.get('close'), style: const TextStyle(color: Colors.white54))",
    "Text('타이머가 \$title(으)로 설정되었습니다.')": "Text(LocalizationService.getFormatted('timer_set_msg', [title]))",
    "_isArchiveTab ? '영구 보관함' : '일반 클립보드'": "_isArchiveTab ? LocalizationService.get('archive') : LocalizationService.get('clipboard')",
    "const Text('연동 해제', style: TextStyle(color: Colors.white))": "Text(LocalizationService.get('logout_title'), style: const TextStyle(color: Colors.white))",
    "const Text('현재 서랍에서 로그아웃하시겠습니까?', style: TextStyle(color: Colors.white70))": "Text(LocalizationService.get('logout_msg'), style: const TextStyle(color: Colors.white70))",
    "const Text('취소', style: TextStyle(color: Colors.white54))": "Text(LocalizationService.get('cancel'), style: const TextStyle(color: Colors.white54))",
    "const Text('로그아웃')": "Text(LocalizationService.get('btn_logout'))",
    "Text('서랍장 메뉴', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))": "Text(LocalizationService.get('menu'), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))",
    "Text('일반 클립보드', style: TextStyle(color: !_isArchiveTab ? Colors.blueAccent : Colors.white))": "Text(LocalizationService.get('clipboard'), style: TextStyle(color: !_isArchiveTab ? Colors.blueAccent : Colors.white))",
    "Text('영구 보관함', style: TextStyle(color: _isArchiveTab ? Colors.blueAccent : Colors.white))": "Text(LocalizationService.get('archive'), style: TextStyle(color: _isArchiveTab ? Colors.blueAccent : Colors.white))",
    "Text('클립보드가 비어 있습니다.\\nPC나 폰에서 내용을 복사해보세요!',": "Text(LocalizationService.get('empty_list'),",
  };

  replacements.forEach((target, replacement) {
    if (!text.contains(target)) {
      print("Warning: Target not found: \$target");
    }
    text = text.replaceAll(target, replacement);
  });

  f.writeAsStringSync(text);
  print("Replaced all strings successfully.");
}
