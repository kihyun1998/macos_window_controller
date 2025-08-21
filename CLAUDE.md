# macOS Window Controller Plugin

이 플러그인은 macOS에서 윈도우 ID 값을 받아 해당 윈도우를 제어하는 기능을 제공하는 Flutter 플러그인입니다.

## 프로젝트 구조
- **플러그인 구현**: `lib/` 폴더에서 Dart API와 method channel 구현
- **네이티브 구현**: `macos/Classes/MacosWindowControllerPlugin.swift`에서 실제 macOS API 호출
- **샘플 앱**: `example/` 폴더에서 플러그인을 사용하는 예제 앱

## Method Channel
- 채널명: `'macos_window_controller'`
- example 폴더의 기존 코드(`'rdp_app/window_manager'`)는 참고용

## 지원 플랫폼
- macOS 전용

## 구현할 함수들

### 기본 윈도우 조작 (우선순위 높음)
- `captureWindow(int windowId)` - 윈도우 스크린샷 (가장 중요)
- `closeWindow(int windowId)` - 윈도우 닫기

### 윈도우 정보 조회
- `getAllWindows()` - 모든 윈도우 리스트
- `getWindowsByPid(int pid)` - 특정 프로세스의 윈도우들
- `getWindowInfo(int windowId)` - 윈도우 상세 정보

### 윈도우 상태 조작
- `focusWindow(int windowId)` - 윈도우 포커스
- `hideWindow(int windowId)` - 윈도우 숨기기
- `showWindow(int windowId)` - 윈도우 보이기
- `minimizeWindow(int windowId)` - 윈도우 최소화

### 유틸리티
- `isWindowValid(int windowId)` - 윈도우 존재 여부 확인

## 구현 순서
1. 쉽고 빠르게 만들 수 있는 기본 함수들부터 시작
2. 캡처 기능이 가장 중요하므로 우선적으로 구현

## 기술 스택
- Flutter Plugin 구조
- Method Channel을 통한 플랫폼 통신
- macOS 네이티브 API:
  - Core Graphics Framework (스크린샷)
  - AppKit Framework (윈도우 조작)
  - Accessibility API (윈도우 정보 조회)