import React, { useEffect, useRef, useState } from "react";
import { motion } from "framer-motion";
import { getOfflineAudioUrl } from "@/lib/audio-cache";

interface EqualizerProps {
    src: string;
    autoPlay?: boolean;
    endTime: string; // ISO datetime string (finished_at)
}

export default function AudioEqualizer({
                                           src,
                                           autoPlay = true,
                                           endTime,
                                       }: EqualizerProps) {
    const audioRef = useRef<HTMLAudioElement | null>(null);
    const [audioSource, setAudioSource] = useState<string>(src);
    const [bars, setBars] = useState<number[]>(new Array(20).fill(0));

    // Resolve offline cached audio blob
    useEffect(() => {
        let isMounted = true;
        if (src) {
            getOfflineAudioUrl(src).then((resolvedUrl) => {
                if (isMounted && resolvedUrl) {
                    setAudioSource(resolvedUrl);
                }
            });
        }
        return () => {
            isMounted = false;
        };
    }, [src]);

    // -----------------------------
    // Equalizer Setup
    // -----------------------------
    useEffect(() => {
        if (!audioRef.current) return;

        const audioCtx = new AudioContext();
        const source = audioCtx.createMediaElementSource(audioRef.current);
        const analyser = audioCtx.createAnalyser();
        analyser.fftSize = 64;

        source.connect(analyser);
        analyser.connect(audioCtx.destination);

        const dataArray = new Uint8Array(analyser.frequencyBinCount);

        const draw = () => {
            analyser.getByteFrequencyData(dataArray);
            setBars(Array.from(dataArray.slice(0, 20)));
            requestAnimationFrame(draw);
        };
        draw();

        return () => {
            audioCtx.close();
        };
    }, []);

    // -----------------------------
    // Track playback time
    // -----------------------------
    useEffect(() => {
        const audio = audioRef.current;
        if (!audio) return;

        const updateTime = () => {
            /* progress is rendered by the equalizer bars; keep listeners so the audio element reports readiness */
        };

        audio.addEventListener("timeupdate", updateTime);
        audio.addEventListener("loadedmetadata", updateTime);

        return () => {
            audio.removeEventListener("timeupdate", updateTime);
            audio.removeEventListener("loadedmetadata", updateTime);
        };
    }, []);

    // -----------------------------
    // Start audio at "remaining time" position
    // -----------------------------
    useEffect(() => {
        const audio = audioRef.current;
        if (!audio) return;

        const handleReady = () => {
            if (!audio.duration || isNaN(audio.duration)) return;

            const endTimestamp = new Date(endTime).getTime();
            const now = Date.now();

            // Seconds remaining until endTime
            const leftSeconds = Math.max(0, Math.floor((endTimestamp - now) / 1000));

            // Start offset = audio duration - remaining time
            const startOffset = Math.max(0, audio.duration - leftSeconds);

            audio.currentTime = startOffset;

            if (autoPlay) {
                audio.play().catch(() => {});
            }
        };

        audio.addEventListener("loadedmetadata", handleReady);

        return () => {
            audio.removeEventListener("loadedmetadata", handleReady);
        };
    }, [endTime, autoPlay]);

    // -----------------------------
    return (
        <div className="flex items-center gap-1">
            {/* Equalizer */}
            <div className="flex items-end gap-[1px] h-3 mr-2">
                {bars.map((value, i) => (
                    <motion.div
                        key={i}
                        className="w-[3px] bg-green-500 rounded-t"
                        animate={{ height: Math.max(2, value / 8) }}
                        transition={{ type: "spring", stiffness: 150, damping: 20 }}
                    />
                ))}
            </div>

            {/* Hidden audio */}
            <audio
                ref={audioRef}
                src={audioSource}
                autoPlay={false}
                controls={false}
                preload="auto"
                style={{ display: "none" }}
            />
        </div>
    );
}
