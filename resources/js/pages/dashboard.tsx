import AppLayout from '@/layouts/app-layout';
import { type BreadcrumbItem, User, Attempt, StatItem, HourlyStatItem, WeeklyStatItem } from '@/types';
import { Head, usePage, Link } from '@inertiajs/react';
import React, { lazy, Suspense } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { useTranslation } from 'react-i18next';

const AttemptsChart = lazy(() => import('@/components/dashboard/AttemptsChart'));
const DailyStatsChart = lazy(() => import('@/components/dashboard/DailyStatsChart'));
const HourlyAttemptsChart = lazy(() => import('@/components/dashboard/HourlyAttemptsChart'));
const WeeklyAttemptsChart = lazy(() => import('@/components/dashboard/WeeklyAttemptsChart'));

const ChartSkeleton = () => (
    <div className="h-64 w-full animate-pulse bg-muted/40 rounded-2xl flex items-center justify-center">
        <span className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Loading chart...</span>
    </div>
);
import { 
    Trophy, 
    Target, 
    TrendingUp, 
    ArrowRight, 
    Clock, 
    CheckCircle2, 
    LayoutDashboard,
    Zap,
    History
} from 'lucide-react';

export default function Dashboard() {
    const { t } = useTranslation();
    const breadcrumbs: BreadcrumbItem[] = [
        {
            title: t('sidebar.dashboard'),
            href: '/dashboard'
        }
    ];

    const { 
        user, 
        recent_attempts = [],
        daily_users = [],
        daily_attempts = [],
        hourly_attempts = [],
        today_hourly_attempts = [],
        weekly_attempts = []
    } = usePage<{ 
        user: User & { total_attempts_count: number }, 
        recent_attempts: Attempt[],
        daily_users: StatItem[],
        daily_attempts: StatItem[],
        hourly_attempts: HourlyStatItem[],
        today_hourly_attempts: HourlyStatItem[],
        weekly_attempts: WeeklyStatItem[]
    }>().props;

    // Calculate averages if available
    const calculateAverage = (typeName: string) => {
        const attempts = user.attempts?.filter(a => a.finished_at) || [];
        if (attempts.length === 0) return 0;
        
        let total = 0;
        let count = 0;
        
        attempts.forEach(a => {
            const type = a.attempt_types?.find(at => at.type?.name === typeName);
            if (type) {
                total += Number(type.is_correct_count || 0);
                count++;
            }
        });
        
        return count > 0 ? (total / count).toFixed(1) : 0;
    };

    const readingAvg = calculateAverage('Reading');
    const listeningAvg = calculateAverage('Listening');

    const isAdmin = Array.isArray(user.roles) 
        ? user.roles.some((r: any) => r.name.toLowerCase() === 'admin') 
        : false;

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title={t('sidebar.dashboard')} />

            <div className="flex flex-col gap-6 p-6 lg:p-8 max-w-7xl mx-auto w-full animate-in fade-in duration-500">
                
                {/* Header Section with Welcome */}
                <div className="relative overflow-hidden rounded-3xl bg-primary/5 p-8 border border-primary/10 backdrop-blur-sm">
                    <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
                        <div>
                            <h1 className="text-3xl font-bold tracking-tight text-foreground">
                                {t('welcome_back')}, <span className="text-primary">{user.name.split(' ')[0]}</span>! 👋
                            </h1>
                            <p className="mt-2 text-muted-foreground max-w-md">
                                {t('ready_to_practice')} {t('performance_overview')}
                            </p>
                        </div>
                        <Link 
                            href="/all-test"
                            className="inline-flex items-center justify-center gap-2 px-6 py-3 rounded-2xl bg-primary text-white font-semibold shadow-lg shadow-primary/20 hover:bg-primary/90 transition-all hover:scale-[1.02] active:scale-[0.98]"
                        >
                            <Zap className="size-5 fill-current" />
                            {t('quick_start')}
                        </Link>
                    </div>
                    
                    {/* Decorative Elements */}
                    <div className="absolute -right-10 -top-10 size-40 bg-primary/10 rounded-full blur-3xl" />
                    <div className="absolute -left-10 -bottom-10 size-40 bg-blue-500/10 rounded-full blur-3xl" />
                </div>

                {/* Main Stats Grid */}
                <div className="grid gap-6 grid-cols-1 sm:grid-cols-2 lg:grid-cols-4">
                    {/* Total Attempts */}
                    <Card className="border-none shadow-sm rounded-3xl overflow-hidden hover:shadow-md transition-shadow">
                        <CardContent className="p-6">
                            <div className="flex items-center gap-4">
                                <div className="p-3 rounded-2xl bg-blue-50 dark:bg-blue-500/10 text-blue-600 dark:text-blue-400">
                                    <Trophy className="size-6" />
                                </div>
                                <div>
                                    <p className="text-sm font-medium text-muted-foreground">{t('total_tests')}</p>
                                    <h3 className="text-2xl font-bold">{user.total_attempts_count}</h3>
                                </div>
                            </div>
                        </CardContent>
                    </Card>

                    {/* Monthly Progress */}
                    <Card className="border-none shadow-sm rounded-3xl overflow-hidden hover:shadow-md transition-shadow">
                        <CardContent className="p-6">
                            <div className="flex items-center gap-4">
                                <div className="p-3 rounded-2xl bg-green-50 dark:bg-green-500/10 text-green-600 dark:text-green-400">
                                    <TrendingUp className="size-6" />
                                </div>
                                <div>
                                    <p className="text-sm font-medium text-muted-foreground">{t('totalAttempts')}</p>
                                    <h3 className="text-2xl font-bold">{user.attempts_count_this_month}</h3>
                                </div>
                            </div>
                        </CardContent>
                    </Card>

                    {/* Reading Avg */}
                    <Card className="border-none shadow-sm rounded-3xl overflow-hidden hover:shadow-md transition-shadow">
                        <CardContent className="p-6">
                            <div className="flex items-center gap-4">
                                <div className="p-3 rounded-2xl bg-purple-50 dark:bg-purple-500/10 text-purple-600 dark:text-purple-400">
                                    <Target className="size-6" />
                                </div>
                                <div>
                                    <p className="text-sm font-medium text-muted-foreground">{t('reading_avg') || 'Reading Avg'}</p>
                                    <h3 className="text-2xl font-bold">{readingAvg}</h3>
                                </div>
                            </div>
                        </CardContent>
                    </Card>

                    {/* Listening Avg */}
                    <Card className="border-none shadow-sm rounded-3xl overflow-hidden hover:shadow-md transition-shadow">
                        <CardContent className="p-6">
                            <div className="flex items-center gap-4">
                                <div className="p-3 rounded-2xl bg-amber-50 dark:bg-amber-500/10 text-amber-600 dark:text-amber-400">
                                    <Target className="size-6" />
                                </div>
                                <div>
                                    <p className="text-sm font-medium text-muted-foreground">{t('listening_avg') || 'Listening Avg'}</p>
                                    <h3 className="text-2xl font-bold">{listeningAvg}</h3>
                                </div>
                            </div>
                        </CardContent>
                    </Card>
                </div>

                {/* Recent Activity */}
                <div className="mb-6">
                    <Card className="border-none shadow-sm rounded-3xl overflow-hidden">
                        <CardHeader className="flex flex-row items-center justify-between border-b border-border pb-4">
                            <CardTitle className="text-lg font-bold flex items-center gap-2">
                                <History className="size-5 text-primary" />
                                {t('recent_activity')}
                            </CardTitle>
                            <Link 
                                href="/attempt" 
                                className="text-sm font-medium text-primary hover:underline flex items-center gap-1"
                            >
                                {t('view_all')}
                                <ArrowRight className="size-3.5" />
                            </Link>
                        </CardHeader>
                        <CardContent className="p-0">
                            <div className="divide-y divide-gray-100 dark:divide-neutral-800">
                                {recent_attempts.length > 0 ? (
                                    recent_attempts.map((attempt) => (
                                        <Link
                                            key={attempt.id}
                                            href={`/attempt/${attempt.id}`}
                                            className="flex items-center justify-between p-5 hover:bg-gray-50 dark:hover:bg-neutral-800/50 transition-colors group"
                                        >
                                            <div className="flex items-center gap-4">
                                                <div className="p-2.5 rounded-xl bg-muted text-muted-foreground group-hover:bg-primary/10 group-hover:text-primary transition-colors">
                                                    <Clock className="size-5" />
                                                </div>
                                                <div>
                                                    <p className="font-semibold text-foreground line-clamp-1">
                                                        {attempt.test?.name || attempt.name}
                                                    </p>
                                                    <p className="text-xs text-muted-foreground mt-0.5">
                                                        {new Date(attempt.finished_at!).toLocaleDateString(undefined, { 
                                                            month: 'short', 
                                                            day: 'numeric',
                                                            hour: '2-digit',
                                                            minute: '2-digit'
                                                        })}
                                                    </p>
                                                </div>
                                            </div>
                                            <div className="flex items-center gap-3">
                                                <div className="flex flex-col items-end">
                                                    <span className="text-xs font-medium text-muted-foreground capitalize">
                                                        {t(String(attempt.status ?? 'finished'))}
                                                    </span>
                                                    <div className="flex items-center gap-1 text-green-600 dark:text-green-400 font-bold">
                                                        <CheckCircle2 className="size-3" />
                                                        <span>
                                                            {attempt.attempt_types?.reduce((sum, t) => sum + (t.is_correct_count || 0), 0)} pts
                                                        </span>
                                                    </div>
                                                </div>
                                                <ArrowRight className="size-4 text-muted-foreground/50 group-hover:text-primary group-hover:translate-x-1 transition-all" />
                                            </div>
                                        </Link>
                                    ))
                                ) : (
                                    <div className="flex flex-col items-center justify-center p-12 text-center">
                                        <div className="p-4 rounded-full bg-muted mb-4">
                                            <LayoutDashboard className="size-8 text-muted-foreground/50" />
                                        </div>
                                        <p className="text-muted-foreground font-medium">{t('no_recent_activity')}</p>
                                    </div>
                                )}
                            </div>
                        </CardContent>
                    </Card>
                </div>

                {/* Charts Section (Admins Only) */}
                {isAdmin && (
                    <Suspense fallback={<ChartSkeleton />}>
                        <div className="grid gap-6 grid-cols-1 mt-6">
                            {/* Analytics Chart */}
                            {(user.attempts?.length ?? 0) > 0 && (
                            <div className="rounded-[2rem] border border-border bg-card p-6 shadow-sm">
                                <h3 className="text-lg font-bold mb-4 flex items-center gap-2">
                                    <TrendingUp className="size-5 text-primary" />
                                    {t('performance_overview')} <span className="text-sm font-normal text-muted-foreground ml-1">{t('last_30_days') || "(last 30 days)"}</span>
                                </h3>
                                <div className="w-full">
                                    <AttemptsChart attempts={user.attempts || []} />
                                </div>
                            </div>
                            )}

                            {/* Daily Stats */}
                            {(daily_users.length > 0 || daily_attempts.length > 0) && (
                                <div className="rounded-[2rem] border border-border bg-card p-6 shadow-sm">
                                    <h3 className="text-lg font-bold mb-4 flex items-center gap-2">
                                        <TrendingUp className="size-5 text-primary" /> {t('daily_activity') || 'Daily Activity'}
                                    </h3>
                                    <DailyStatsChart dailyUsers={daily_users} dailyAttempts={daily_attempts} />
                                </div>
                            )}

                            {/* Hourly Stats Row (Today vs All-time) */}
                            <div className="grid gap-6 grid-cols-1 lg:grid-cols-2">
                                {/* Today Hourly Stats */}
                                <div className="rounded-[2rem] border border-border bg-card p-6 shadow-sm">
                                    <HourlyAttemptsChart title={t('todays_hourly_stats') || "Today's hourly stats"} data={today_hourly_attempts} />
                                </div>

                                {/* All-time Hourly Stats */}
                                {hourly_attempts.length > 0 && (
                                    <div className="rounded-[2rem] border border-border bg-card p-6 shadow-sm">
                                        <HourlyAttemptsChart title={t('all_time_hourly_distribution') || 'All-time hourly distribution'} data={hourly_attempts} />
                                    </div>
                                )}
                            </div>

                            {/* Weekly Stats */}
                            {weekly_attempts.length > 0 && (
                                <div className="rounded-[2rem] border border-border bg-card p-6 shadow-sm">
                                    <WeeklyAttemptsChart title={t('all_time_weekly_attempts_distribution') || 'All-time Weekly Attempts Distribution'} data={weekly_attempts} />
                                </div>
                            )}
                        </div>
                    </Suspense>
                )}
            </div>
        </AppLayout>
    );
}
