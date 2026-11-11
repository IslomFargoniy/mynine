import { motion } from 'framer-motion';
import { Loader2 } from 'lucide-react';
import { useTranslation } from 'react-i18next';

export default function SplashScreen() {
    const { t } = useTranslation();
    return (
        <div className="fixed inset-0 flex flex-col items-center justify-center bg-background z-[9999]">
            <motion.div
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, ease: 'easeOut' }}
                className="flex flex-col items-center gap-8"
            >
                <div className="relative">
                    <motion.div
                        animate={{
                            scale: [1, 1.05, 1],
                        }}
                        transition={{
                            duration: 2,
                            repeat: Infinity,
                            ease: 'easeInOut',
                        }}
                    >
                        <img
                            src="/images/logo/logo.png"
                            alt={t('common.logo')}
                            className="h-28 w-28 rounded-3xl object-contain drop-shadow-2xl"
                        />
                    </motion.div>
                    
                    {/* Subtle glow effect behind logo */}
                    <div className="absolute inset-0 -z-10 bg-primary/20 blur-3xl rounded-full scale-150 animate-pulse" />
                </div>

                <div className="flex flex-col items-center gap-4">
                    <div className="flex items-center gap-3">
                        <Loader2 className="h-5 w-5 animate-spin text-brand" />
                        <span className="text-sm font-semibold tracking-[0.2em] text-muted-foreground uppercase">
                            {t('splash.loading')}
                        </span>
                    </div>
                    
                    <div className="flex gap-1.5">
                        {[0, 1, 2].map((i) => (
                            <motion.div
                                key={i}
                                animate={{
                                    opacity: [0.3, 1, 0.3],
                                    scale: [1, 1.2, 1],
                                }}
                                transition={{
                                    duration: 1.5,
                                    repeat: Infinity,
                                    delay: i * 0.2,
                                    ease: 'easeInOut',
                                }}
                                className="h-1.5 w-1.5 rounded-full bg-primary/60"
                            />
                        ))}
                    </div>
                </div>
            </motion.div>
            
            {/* Bottom text/version info for a premium feel */}
            <motion.div 
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 1, duration: 1 }}
                className="absolute bottom-10 text-[10px] font-medium text-muted-foreground uppercase tracking-[0.3em]"
            >
                {t('splash.powered_by')}
            </motion.div>
        </div>
    );
}
