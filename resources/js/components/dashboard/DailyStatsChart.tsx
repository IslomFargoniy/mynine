import React from 'react';
import Chart from 'react-apexcharts';
import { StatItem } from '@/types';
import { useIsDark } from '@/hooks/use-is-dark';
import { serverWallClock } from '@/lib/server-time';

interface Props {
    dailyUsers: StatItem[];
    dailyAttempts: StatItem[];
}

export default function DailyStatsChart({ dailyUsers, dailyAttempts }: Props) {
    const isDark = useIsDark();
    const axisLabel = isDark ? '#CBD5E1' : '#334155';
    const brand = isDark ? '#818CF8' : '#4F46E5';

    const allDates = Array.from(new Set([
        ...dailyUsers.map(d => d.day_date),
        ...dailyAttempts.map(d => d.day_date)
    ])).sort();

    const labels = allDates.map(date => 
        (serverWallClock(date) ?? new Date()).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
    );

    const newUsersData = allDates.map(date => {
        const item = dailyUsers.find(d => d.day_date === date);
        return item ? Number(item.items_count) : 0;
    });

    const uniqueAttemptUsersData = allDates.map(date => {
        const item = dailyAttempts.find(d => d.day_date === date);
        return item && item.unique_users_count ? Number(item.unique_users_count) : 0;
    });

    const repeatAttemptsData = allDates.map(date => {
        const item = dailyAttempts.find(d => d.day_date === date);
        const total = item ? Number(item.items_count) : 0;
        const unique = item && item.unique_users_count ? Number(item.unique_users_count) : 0;
        return Math.max(0, total - unique);
    });


    const options: ApexCharts.ApexOptions = {
        chart: {
            type: 'bar',
            stacked: true,
            toolbar: { show: false },
            zoom: { enabled: false },
            fontFamily: 'inherit',
            background: 'transparent',
        },
        theme: {
            mode: isDark ? 'dark' : 'light'
        },
        plotOptions: {
            bar: {
                horizontal: false,
                borderRadius: 4,
                columnWidth: '60%',
            },
        },
        dataLabels: { enabled: false },
        xaxis: {
            categories: labels,
            labels: {
                style: { colors: axisLabel, fontSize: '12px' }
            },
            axisBorder: { show: false },
            axisTicks: { show: false },
        },
        yaxis: {
            labels: {
                style: { colors: axisLabel, fontSize: '12px' }
            }
        },
        grid: {
            borderColor: isDark ? 'rgba(255, 255, 255, 0.10)' : 'rgba(15, 23, 42, 0.08)',
            strokeDashArray: 4,
        },
        legend: {
            position: 'top',
            horizontalAlign: 'right',
            fontFamily: 'inherit',
            markers: { size: 4 },
            labels: { colors: axisLabel },
        },
        colors: [brand, '#10b981', '#14b8a6'],
        tooltip: {
            theme: isDark ? 'dark' : 'light',
        }
    };

    const series = [
        { name: 'New Users', data: newUsersData },
        { name: 'Unique Attempt Users', data: uniqueAttemptUsersData },
        { name: 'Repeat Attempts', data: repeatAttemptsData }
    ];

    return (
        <div className="w-full h-[340px]">
            <Chart options={options} series={series} type="bar" height="100%" />
        </div>
    );
}
