# Roger Studio — image ComfyUI สำหรับเช่าบน vast.ai (แม่แบบสำเร็จรูปของเราเอง)
#
# ชุดเวอร์ชันนี้ทดสอบแล้วว่าเรนเดอร์ MiniMax H3 ได้จริงบน RTX 5090 (ComfyUI ที่เก่า/ใหม่กว่านี้เคย OOM หรือได้ภาพ noise)
# โมเดลไม่อยู่ใน image (~117 GB) — entrypoint.sh โหลดลง /workspace/models ตอนเปิดเครื่อง แล้วค่อยเปิด ComfyUI
FROM nvidia/cuda:13.0.3-base-ubuntu24.04

ARG COMFYUI_SHA=95d755cd8107a72258d452b5d3657273d571f07d
ARG KJNODES_SHA=e8e88f7c88e3f6205b122f5de87e69a09fbce5ac
ARG VHS_SHA=115de7a9d9e34410cffb9ecfd268e993b11a50fb
ARG H3_UPSCALER_SHA=d7c01b9011f2e8439493f6c02c29995a27df276f
ARG MANAGER_SHA=f39cbd56fecae0b27a446c0cd450cd591f3a8bea
ARG DOWNLOADER_SHA=c48061e234cb5bf0e17d82a88e546c049f8fa441
ARG T8_SHA=b6be56527a016f2b9a999432bb30acfa68307e7c
ARG TORCH_VERSION=2.9.1
ARG TORCHVISION_VERSION=0.24.1
ARG TORCHAUDIO_VERSION=2.9.1
ARG TORCH_INDEX=https://download.pytorch.org/whl/cu130
ARG TRANSFORMERS_VERSION=5.3.0
ARG SAGEATTENTION_WHEEL=https://huggingface.co/vjump21848/sageattention-pre-compiled-wheel/resolve/main/sageattention-2.2.0%2Bcu130-cp312-cp312-linux_x86_64.whl

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PATH=/opt/venv/bin:/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    COMFYUI_DIR=/opt/ComfyUI \
    WORKSPACE=/workspace

RUN apt-get update && apt-get install -y --no-install-recommends \
        python3.12 python3.12-venv git curl ca-certificates aria2 ffmpeg libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/* \
    && python3.12 -m venv /opt/venv \
    && pip install --upgrade pip

RUN pip install "torch==${TORCH_VERSION}" "torchvision==${TORCHVISION_VERSION}" "torchaudio==${TORCHAUDIO_VERSION}" \
        --index-url "${TORCH_INDEX}"

RUN git clone https://github.com/comfyanonymous/ComfyUI.git "${COMFYUI_DIR}" \
    && git -C "${COMFYUI_DIR}" checkout --detach "${COMFYUI_SHA}" \
    && rm -rf "${COMFYUI_DIR}/.git" \
    && pip install -r "${COMFYUI_DIR}/requirements.txt" \
    && pip install "transformers==${TRANSFORMERS_VERSION}" "${SAGEATTENTION_WHEEL}"

# ส่วนเสริม: KJNodes / VideoHelperSuite / ตัวขยาย latent ของ H3 / Manager / HF Downloader (ปุ่ม "ติดตั้งโมเดลที่ขาด" ในโปรแกรมใช้)
# / T8 v1.97.0 (sampler Dual-Clock ของวิดีโอผิวสมจริง Singularity Balanced)
RUN set -eux; cd "${COMFYUI_DIR}/custom_nodes"; \
    for spec in \
        "https://github.com/kijai/ComfyUI-KJNodes.git ComfyUI-KJNodes ${KJNODES_SHA}" \
        "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git ComfyUI-VideoHelperSuite ${VHS_SHA}" \
        "https://github.com/LBH-123-AI/Comfyui_Minimax_h3_latent_Upscaler.git Comfyui_Minimax_h3_latent_Upscaler ${H3_UPSCALER_SHA}" \
        "https://github.com/ltdrdata/ComfyUI-Manager.git ComfyUI-Manager ${MANAGER_SHA}" \
        "https://github.com/ciri/comfyui-model-downloader.git comfyui-model-downloader ${DOWNLOADER_SHA}" \
        "https://github.com/T8mars/comfyui-minimax-h3-audio-T8.git comfyui-minimax-h3-audio-T8 ${T8_SHA}" \
    ; do \
        set -- $spec; \
        git clone "$1" "$2"; \
        git -C "$2" checkout --detach "$3"; \
        rm -rf "$2/.git"; \
        if [ -f "$2/requirements.txt" ]; then pip install -r "$2/requirements.txt"; fi; \
    done

WORKDIR /opt/roger
COPY entrypoint.sh models.txt ./
RUN chmod +x entrypoint.sh

EXPOSE 8188
CMD ["/opt/roger/entrypoint.sh"]
