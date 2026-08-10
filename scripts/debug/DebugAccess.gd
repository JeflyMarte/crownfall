class_name DebugAccess
extends RefCounted

## 出荷ビルドではデバッグ UI／フル所持入口を出さない。
## Godot: エディタ／debug エクスポートで true、release テンプレートで false。


static func is_allowed() -> bool:
	return OS.is_debug_build()
