# roger-comfy

Docker image ComfyUI สำหรับเช่าเครื่องบน vast.ai จากโปรแกรม Roger Studio ("แม่แบบสำเร็จรูป")

- ชุดเวอร์ชันที่เรนเดอร์ MiniMax H3 ได้จริง: CUDA 13.0 · torch 2.9.1 (cu130) · ComfyUI `95d755c` · transformers 5.3.0 · SageAttention 2.2.0
- ส่วนเสริม: KJNodes, VideoHelperSuite, Minimax H3 latent upscaler, ComfyUI-Manager, comfyui-model-downloader (HF Downloader), T8 v1.97.0 (sampler Dual-Clock ของวิดีโอผิวสมจริง), Nvidia VFX Nodes 0.2.0 (RTX Video Super Resolution)
- เปิดเครื่อง (`entrypoint.sh`): โหลดโมเดลใน `models.txt` (H3 แบบเร็ว + Singularity Balanced + Qwen ~117 GB — เช่าดิสก์ 150 GB) ลง `/workspace/models` แล้วเปิด ComfyUI พอร์ต 8188
- `models.txt` ต้องตรงกับ `still_qwen.DOWNLOADS` + `video_h3.DOWNLOADS` ในโปรแกรม (`app/tests/test_image.py` ตรวจ)

push ขึ้น `main` → GitHub Actions สร้าง `ghcr.io/gotroger/roger-comfy:latest` และ `:<วันที่>-<ครั้งที่>`
