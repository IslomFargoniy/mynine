import React, { useRef, useState, useEffect } from 'react';
import { Play, Pause, Volume2, VolumeX, Gauge } from 'lucide-react';

interface AudioPlayerProps {
    src: string;
    className?: string;
}

export default function EnhancedAudioPlayer({ src, className = '' }: AudioPlayerProps) {
    const audioRef = useRef<HTMLAudioElement>(null);
    const [isPlaying, setIsPlaying] = useState(false);
    const [currentTime, setCurrentTime] = useState(0);
    const [duration, setDuration] = useState(0);
    const [playbackRate, setPlaybackRate] = useState(1.0);
    const [isMuted, setIsMuted] = useState(false);

    useEffect(() => {
        const audio = audioRef.current;
        if (!audio) return;

        const updateTime = () => setCurrentTime(audio.currentTime);
        const updateDuration = () => setDuration(audio.duration || 0);
        const handleEnded = () => setIsPlaying(false);

        audio.addEventListener('timeupdate', updateTime);
        audio.addEventListener('loadedmetadata', updateDuration);
        audio.addEventListener('ended', handleEnded);

        return () => {
            audio.removeEventListener('timeupdate', updateTime);
            audio.removeEventListener('loadedmetadata', updateDuration);
            audio.removeEventListener('ended', handleEnded);
        };
    }, []);

    const togglePlay = () => {
        const audio = audioRef.current;
        if (!audio) return;

        if (isPlaying) {
            audio.pause();
            setIsPlaying(false);
        } else {
            audio.play().then(() => setIsPlaying(true)).catch(e => console.error(e));
        }
    };

    const changeSpeed = (rate: number) => {
        setPlaybackRate(rate);
        if (audioRef.current) {
            audioRef.current.playbackRate = rate;
        }
    };

    const toggleMute = () => {
        if (audioRef.current) {
            audioRef.current.muted = !isMuted;
            setIsMuted(!isMuted);
        }
    };

    const handleSeek = (e: React.ChangeEvent<HTMLInputElement>) => {
        const newTime = parseFloat(e.target.value);
        setCurrentTime(newTime);
        if (audioRef.current) {
            audioRef.current.currentTime = newTime;
        }
    };

    const formatTime = (seconds: number) => {
        if (isNaN(seconds)) return '00:00';
        const mins = Math.floor(seconds / 60);
        const secs = Math.floor(seconds % 60);
        return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    };

    const speeds = [0.75, 1.0, 1.25, 1.5];

    return (
        <div className={`glass-subtle p-3 rounded-[18px] space-y-2.5 ${className}`}>
            <audio ref={audioRef} src={src} preload="auto" />

            <div className="flex items-center gap-3">
                {/* Play/Pause Button */}
                <button
                    type="button"
                    onClick={togglePlay}
                    className="btn-glass-primary p-2.5 rounded-full hover:brightness-110 active:scale-95 text-primary-foreground transition-all cursor-pointer"
                >
                    {isPlaying ? <Pause className="w-4 h-4" /> : <Play className="w-4 h-4 ml-0.5" />}
                </button>

                {/* Progress Bar & Time */}
                <div className="flex-1 space-y-1">
                    <input
                        type="range"
                        min={0}
                        max={duration || 100}
                        value={currentTime}
                        onChange={handleSeek}
                        className="w-full h-1.5 accent-primary rounded-full cursor-pointer bg-foreground/10"
                    />
                    <div className="flex justify-between text-[10px] font-bold text-muted-foreground">
                        <span>{formatTime(currentTime)}</span>
                        <span>{formatTime(duration)}</span>
                    </div>
                </div>

                {/* Mute Button */}
                <button
                    type="button"
                    onClick={toggleMute}
                    className="p-2 rounded-full text-muted-foreground hover:bg-accent transition-colors cursor-pointer"
                >
                    {isMuted ? <VolumeX className="w-4 h-4 text-rose-500" /> : <Volume2 className="w-4 h-4" />}
                </button>

                {/* Speed Select Buttons */}
                <div className="flex items-center gap-1 bg-muted border border-glass-edge p-1 rounded-full">
                    <Gauge className="w-3.5 h-3.5 text-muted-foreground ml-1 mr-0.5" />
                    {speeds.map(rate => (
                        <button
                            key={rate}
                            type="button"
                            onClick={() => changeSpeed(rate)}
                            className={`px-1.5 py-0.5 rounded-full text-[10px] font-bold transition-all cursor-pointer ${
                                playbackRate === rate
                                    ? 'bg-primary text-primary-foreground shadow-glass-pill'
                                    : 'text-muted-foreground hover:bg-accent'
                            }`}
                        >
                            {rate}x
                        </button>
                    ))}
                </div>
            </div>
        </div>
    );
}
