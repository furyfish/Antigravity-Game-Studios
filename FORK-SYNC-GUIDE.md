# 🔄 Hướng Dẫn Đồng Bộ Fork Cho Antigravity Game Studios
# (Upstream Fork Synchronization Guide)

Tài liệu này hướng dẫn chi tiết cách đồng bộ các bản cập nhật mới nhất từ kho lưu trữ gốc (upstream) **[Claude-Code-Game-Studios](https://github.com/Donchitos/Claude-Code-Game-Studios)** về fork **[Antigravity-Game-Studios](https://github.com/furyfish/Antigravity-Game-Studios)** mà vẫn đảm bảo tính tương thích 100% với môi trường **Google Antigravity** (cả **Antigravity App/IDE** và **Antigravity CLI**).

---

## 1. Kiến Trúc Đồng Bộ & Nguyên Lý Hoạt Động

### 1.1. Mối Quan Hệ Giữa Upstream & Fork

- **Upstream (Gốc)**: `https://github.com/Donchitos/Claude-Code-Game-Studios` — Được thiết kế ban đầu cho **Claude Code**, cấu trúc dữ liệu lưu trong `.claude/` và hướng dẫn gốc trong `CLAUDE.md`.
- **Fork (Hiện tại)**: `https://github.com/furyfish/Antigravity-Game-Studios` — Được port sang **Antigravity**, hỗ trợ song song cả **Antigravity (IDE & CLI)** và **Claude Code**.

### 1.2. Giải Pháp Kiến Trúc Symlink Kép (Dual-Symlink Pattern)

Để tránh xung đột Git (Merge Conflicts) nghiêm trọng khi upstream thêm, sửa, xóa file, dự án sử dụng chiến lược **Dual-Symlink**:

```text
                                  ┌────────────────────────┐
                                  │ .claude/               │
                                  │ (Thư mục vật lý Git)   │
                                  └───────────▲────────────┘
                                              │
                         ┌────────────────────┴────────────────────┐
                         │                                         │
             ┌───────────┴──────────┐                  ┌───────────┴──────────┐
             │ .agent               │                  │ .antigravity         │
             │ (Symlink Antigravity)│                  │ (Symlink Dự phòng)   │
             └──────────────────────┘                  └──────────────────────┘
```

1. **Thư mục thật `.claude/` được giữ nguyên**: Upstream commit vào `.claude/`. Vì vậy, khi `git merge upstream/main`, Git sử dụng thuật toán `ort` (Osprey/Oysterpack Recursive Turbo) để tự động merge mọi cập nhật file trong `.claude/` mà không bị lỗi đổi tên thư mục (Directory Rename Conflict).
2. **`.agent` và `.antigravity` là symlink trỏ vào `.claude`**:
   - Antigravity IDE và CLI đọc `.agent/rules/`, `.agent/skills/`, `.agent/agents/`, `.agent/workflows/`, `.agent/hooks/`, `.agent/scripts/`.
   - Ngay khi `.claude/` nhận commit mới từ upstream, `.agent/` lập tức có dữ liệu mới nhất mà không cần copy hay nhân bản dữ liệu.
3. **Các file hướng dẫn đồng bộ**:
   - `ANTIGRAVITY.md` là file hướng dẫn gốc dành riêng cho Antigravity.
   - `GEMINI.md` và `AGENTS.md` là symlink trỏ đến `ANTIGRAVITY.md`.
   - `CLAUDE.md` tiếp tục nhận cập nhật từ upstream.
   - Trong các thư mục con (`design/`, `docs/`, `src/`, `CCGS Skill Testing Framework/`), `ANTIGRAVITY.md` là symlink trỏ đến `CLAUDE.md`.

---

## 2. Cách Đồng Bộ Nhanh (Khuyến Nghị — 1 Bước)

Dự án đã tích hợp sẵn script tự động hóa: `scripts/sync-upstream.sh`.

### 2.1. Kiểm tra trước xem có commit mới không (Dry-run / Check Mode)
```bash
bash scripts/sync-upstream.sh --check
```

### 2.2. Tiến hành tự động đồng bộ
```bash
bash scripts/sync-upstream.sh
```

**Script này sẽ tự động**:
1. Kiểm tra git working tree (đảm bảo không mất mát code chưa commit).
2. Tự động thêm remote `upstream` nếu chưa có.
3. Tải về nhánh `upstream/main`.
4. Hợp nhất (merge) các commit mới vào nhánh hiện tại.
5. Tự động kiểm tra và sửa/tái tạo toàn bộ symlinks (`.agent`, `.antigravity`, `workflows`, `GEMINI.md`, `AGENTS.md`, các symlinks con).
6. Tự động cấp quyền thực thi (`chmod +x`) cho tất cả hook và script.
7. Chạy kiểm tra tính mạch lạc (`project-coherence.sh`).

---

## 3. Quy Trình Đồng Bộ Thủ Công Từng Bước (Manual Step-by-Step)

Nếu bạn muốn tự tay kiểm soát từng câu lệnh Git:

### Bước 1: Đảm bảo working tree sạch sẽ
```bash
git status
# Nếu có thay đổi chưa commit:
git stash
```

### Bước 2: Kiểm tra hoặc thêm remote upstream
```bash
git remote -v
# Nếu chưa có upstream:
git remote add upstream https://github.com/Donchitos/Claude-Code-Game-Studios.git
```

### Bước 3: Fetch dữ liệu mới từ upstream
```bash
git fetch upstream main
```

### Bước 4: Xem trước danh sách commit mới
```bash
git log --oneline HEAD..upstream/main
```

### Bước 5: Merge upstream vào nhánh làm việc (thường là `main`)
```bash
git merge upstream/main -m "chore(sync): merge upstream main into Antigravity-Game-Studios"
```

### Bước 6: Sửa lại symlinks & quyền thực thi
Chạy lệnh repair có sẵn:
```bash
bash scripts/sync-upstream.sh --repair
```
Hoặc chạy thủ công:
```bash
ln -sf .claude .agent
ln -sf .claude .antigravity
(cd .claude && ln -sf skills workflows)
ln -sf ANTIGRAVITY.md GEMINI.md
ln -sf ANTIGRAVITY.md AGENTS.md

for dir in design docs src "CCGS Skill Testing Framework"; do
  (cd "$dir" && ln -sf CLAUDE.md ANTIGRAVITY.md && ln -sf ANTIGRAVITY.md GEMINI.md && ln -sf ANTIGRAVITY.md AGENTS.md)
done
ln -sf "CCGS Skill Testing Framework" "AGS Skill Testing Framework"

chmod +x .claude/hooks/*.sh .claude/scripts/*.sh .claude/statusline.sh scripts/*.sh 2>/dev/null || true
```

### Bước 7: Kiểm tra tính toàn vẹn của dự án
```bash
bash .agent/scripts/project-coherence.sh
```

### Bước 8: Push lên GitHub của bạn
```bash
git push origin main
```

---

## 4. Xử Lý Xung Đột (Conflict Resolution Playbook)

Nhờ kiến trúc symlink, 99% các lần sync sẽ tự động merge thành công không có conflict. Tuy nhiên, nếu có conflict, hãy xử lý theo quy tắc sau:

### 4.1. Xung đột tại `CLAUDE.md`
- **Nguyên nhân**: Upstream cập nhật hướng dẫn mới trong `CLAUDE.md`.
- **Cách xử lý**:
  - Chấp nhận thay đổi từ upstream (`git checkout --theirs CLAUDE.md` hoặc giữ cả hai).
  - Mở `ANTIGRAVITY.md` và cập nhật các nội dung mới tương ứng nếu có tính năng mới (ví dụ agent mới, skill mới).

### 4.2. Xung đột tại `project.yaml`
- **Nguyên nhân**: Upstream thay đổi `framework.version` hoặc cấu hình mẫu.
- **Cách xử lý**: Giữ `framework.version` mới từ upstream, kiểm tra không để mất các thiết lập Antigravity tùy biến.

### 4.3. Xung đột tại `.claude/hooks/` hoặc `.claude/scripts/`
- **Nguyên nhân**: Upstream cập nhật logic hook hoặc script.
- **Cách xử lý**:
  - Đảm bảo khối tìm kiếm thư mục gốc (Root resolution) luôn chứa fallback cho Antigravity:
  ```bash
  if [ -f "project.yaml" ] || [ -d ".agent" ] || [ -d ".antigravity" ] || [ -d ".claude" ]; then
    CCGS_ROOT="$PWD"
  elif [ -n "${ANTIGRAVITY_PROJECT_DIR:-}" ] && [ -d "${ANTIGRAVITY_PROJECT_DIR}" ]; then
    CCGS_ROOT="$ANTIGRAVITY_PROJECT_DIR"
  elif [ -n "${GEMINI_PROJECT_DIR:-}" ] && [ -d "${GEMINI_PROJECT_DIR}" ]; then
    CCGS_ROOT="$GEMINI_PROJECT_DIR"
  elif [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "${CLAUDE_PROJECT_DIR}" ]; then
    CCGS_ROOT="$CLAUDE_PROJECT_DIR"
  else
    CCGS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
  fi
  AGS_ROOT="$CCGS_ROOT"
  ```
  - Sau khi giải quyết conflict, chạy `bash scripts/sync-upstream.sh --repair`.

### 4.4. Xung đột tại `.claude/settings.json`
- **Nguyên nhân**: Upstream thêm hook mới hoặc thay đổi matcher.
- **Cách xử lý**:
  - Đảm bảo mọi đường dẫn command gọi hook dùng mẫu an toàn:
    `"${CLAUDE_PROJECT_DIR:-${ANTIGRAVITY_PROJECT_DIR:-.}}/.claude/hooks/..."`
  - Giúp hook chạy an toàn ngay cả khi biến `$CLAUDE_PROJECT_DIR` chưa được set.

---

## 5. Danh Sách Kiểm Tra Sau Mỗi Lần Sync (Post-Sync Checklist)

- [ ] `.agent` là symlink trỏ đến `.claude` (`ls -l .agent`).
- [ ] `.antigravity` là symlink trỏ đến `.claude` (`ls -l .antigravity`).
- [ ] `ANTIGRAVITY.md` có đầy đủ thông tin cập nhật.
- [ ] `GEMINI.md` và `AGENTS.md` trỏ đến `ANTIGRAVITY.md`.
- [ ] Tất cả 14 hooks trong `.agent/hooks/` có quyền thực thi (`chmod +x`).
- [ ] Tất cả 10 scripts trong `.agent/scripts/` có quyền thực thi (`chmod +x`).
- [ ] Lệnh `bash .agent/scripts/project-coherence.sh` chạy thành công (exit code 0).
- [ ] Lệnh `bash .agent/hooks/session-start.sh` hiển thị session context đầy đủ.
- [ ] Slash command `/start` và `/setup-engine` sẵn sàng trong Antigravity IDE.

---

## 6. Hỗ Trợ Đa Nền Tảng (Antigravity IDE & Antigravity CLI)

| Tính năng | Antigravity IDE / App | Antigravity CLI | Claude Code |
|-----------|------------------------|-----------------|-------------|
| File hướng dẫn | `ANTIGRAVITY.md` | `GEMINI.md` / `ANTIGRAVITY.md` | `CLAUDE.md` |
| Thư mục Agent | `.agent/` | `.agent/` | `.claude/` |
| Subagents (49) | `.agent/agents/*.md` | `.agent/agents/*.md` | `.claude/agents/*.md` |
| Skills & Workflows (74) | `.agent/skills/` & `.agent/workflows/` | `.agent/skills/` | `.claude/skills/` |
| Rules (13) | `.agent/rules/*.md` | `.agent/rules/*.md` | `.claude/rules/*.md` |
| Tool Call Mapping | `view_file`, `write_to_file`, `replace_file_content`, `run_command`, `ask_question` | Native CLI tools | `Read`, `Write`, `Edit`, `Bash` |
| Trạng thái phiên | `production/session-state/active.md` | `production/session-state/active.md` | `production/session-state/active.md` |
| Statusline | Terminal status | `.agent/statusline.sh` | `.claude/statusline.sh` |
