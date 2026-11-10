import React from 'react';
import Chart from 'react-apexcharts';
import { HourlyStatItem } from '@/types';
import { useIsDark } from '@/hooks/use-is-dark';

interface Props {
    title: string;
    data: HourlyStatItem[];
}

export default function HourlyAttemptsChart({ title, data: chartData }: Props) {
    const isDark = useIsDark();
    const axisLabel = isDark ? '#CBD5E1' : '#334155';
    const brand = isDark ? '#818CF8' : '#4F46E5';
    
    const hours = Array.from({ length: 24 }, (_, i) => i);
    const labels = hours.map(h => `${h.toString().padStart(2, '0')}:00`);
    
    const dataPoints = hours.map(h => {
        const item = chartData.find(d => Number(d.hour) === h);
        return item ? Number(item.items_count) : 0;
    });


    const options: ApexCharts.ApexOptions = {
        chart: {
            type: 'bar',
            toolbar: { show: false },
            zoom: { enabled: false },
            fontFamily: 'inherit',
            background: 'transparent',
        },
        theme: {
            mode: isDark ? 'dark' : 'light'
        },
        title: {
            text: title,
            align: 'left',
            style: {
                fontSize: '14px',
                fontWeight: 'bold',
                color: axisLabel
            }
        },
        plotOptions: {
            bar: {
                borderRadius: 4,
                columnWidth: '70%',
            }
        },
        dataLabels: { enabled: false },
        xaxis: {
            categories: labels,
            labels: {
                style: { colors: axisLabel, fontSize: '10px' },
                rotate: -45,
            },
            axisBorder: { show: false },
            axisTicks: { show: false },
        },
        yaxis: {
            labels: {
                style: { colors: axisLabel, fontSize: '11px' }
            }
        },
        grid: {
            borderColor: isDark ? 'rgba(255, 255, 255, 0.10)' : 'rgba(15, 23, 42, 0.08)',
            strokeDashArray: 4,
        },
        colors: [brand],
        tooltip: {
            theme: isDark ? 'dark' : 'light',
        }
    };

    const series = [{
        name: 'Attempts',
        data: dataPoints
    }];

    return (
        <div className="w-full h-[340px]">
            <Chart options={options} series={series} type="bar" height="100%" />
        </div>
    );
}
