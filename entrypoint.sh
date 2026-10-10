#!/bin/bash
# Roger Studio — เปิดเครื่อง: โหลดโมเดลที่ยังไม่มี (MiniMax H3 + Qwen) ลง /workspace/models แล้วค่อยเปิด ComfyUI
# (เปิด ComfyUI หลังโมเดลครบ เพราะโปรแกรมส่งงานให้ทันทีที่ ComfyUI ตอบ) · log ทั้งหมดออก stdout = ปุ่ม log ในโปรแกรม
set -uo pipefail

W="${WORKSPACE:-/workspace}"
M="$W/models"
PORT="${COMFYUI_PORT:-8188}"
LIST="${MODELS_LIST:-/opt/roger/models.txt}"
log() { echo "[roger] $(date +%H:%M:%S) $*"; }

mkdir -p "$M" "$W/input" "$W/output" "$W/temp" "$W/user"

# ---------------------------------------------------------------- โมเดล
# models.txt: "หมวด|URL" ต่อบรรทัด — ตรงกับรายการที่โปรแกรมตรวจ (still_qwen + video_h3 DOWNLOADS)
todo="$(mktemp)"
missing=0
while IFS='|' read -r cat url; do
    [ -z "$cat" ] || [ "${cat:0:1}" = "#" ] && continue
    file="$(basename "${url%%\?*}")"
    mkdir -p "$M/$cat"
    # aria2 ทิ้งไฟล์ .aria2 ไว้ระหว่างโหลด — มีไฟล์และไม่มี .aria2 = ครบแล้ว
    if [ -f "$M/$cat/$file" ] && [ ! -f "$M/$cat/$file.aria2" ]; then continue; fi
    missing=$((missing + 1))
    {
        echo "$url"
        echo "  dir=$M/$cat"
        echo "  out=$file"
        # โมเดลชุดนี้เป็นสาธารณะ — ใส่ token เฉพาะเมื่อมี (เผื่อ repo ที่ต้องยอมรับ license)
        [ -n "${HF_TOKEN:-}" ] && [[ "$url" == https://huggingface.co/* ]] && echo "  header=Authorization: Bearer $HF_TOKEN"
    } >> "$todo"
done < "$LIST"

if [ "$missing" -gt 0 ]; then
    log "กำลังโหลดโมเดล $missing ไฟล์ ลง $M"
    aria2c -i "$todo" -j 4 -x 8 -s 8 --continue=true --auto-file-renaming=false --allow-overwrite=true \
        --max-tries=5 --retry-wait=10 --console-log-level=warn --summary-interval=30 --download-result=full \
        || log "โหลดโมเดลบางไฟล์ไม่สำเร็จ — เปิด ComfyUI ต่อ (กด “ติดตั้งโมเดลที่ขาด” ในโปรแกรมได้)"
else
    log "มีโมเดลครบแล้ว"
fi
rm -f "$todo"
log "พื้นที่ดิสก์: $(df -h "$W" | awk 'NR==2 {print $3 " ใช้ไป / " $2 " (เหลือ " $4 ")"}')"

# ---------------------------------------------------------------- ComfyUI
ARGS=(
    --listen 0.0.0.0
    --port "$PORT"
    --models-directory "$M"
    --input-directory "$W/input"
    --output-directory "$W/output"
    --temp-directory "$W/temp"
    --user-directory "$W/user"
)
[ "${USE_SAGE_ATTENTION:-true}" = "true" ] && ARGS+=(--use-sage-attention)

log "เปิด ComfyUI พอร์ต $PORT"
cd "${COMFYUI_DIR:-/opt/ComfyUI}"
exec python main.py "${ARGS[@]}"
