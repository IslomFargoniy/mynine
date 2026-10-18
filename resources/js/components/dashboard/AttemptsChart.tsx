import { useAppearance } from '@/hooks/use-appearance';
import Chart from 'react-apexcharts';
import { Attempt } from '@/types';


export default function AttemptsChart({ attempts }: { attempts: Attempt[] }) {
    const { appearance } = useAppearance();
    if (!attempts || attempts.length === 0) return null;

    const labels = attempts.map(a => 
        new Date(a.finished_at!).toLocaleDateString('en-US', {
            month: 'short',
            day: 'numeric'
        })
    );

    const dataPoints = attempts.map(a => 
        a.attempt_types?.reduce((sum, t) => sum + (Number(t.is_correct_count) || 0), 0) || 0
    );

    const options: ApexCharts.ApexOptions = {
        chart: {
            type: 'area',
            toolbar: { show: false },
            zoom: { enabled: false },
            fontFamily: 'inherit',
            background: 'transparent',
            animations: { enabled: true }
        },
        theme: {
            mode: appearance === 'system' 
                ? (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
                : (appearance as 'light' | 'dark')
        },
        dataLabels: { enabled: false },
        stroke: {
            curve: 'smooth',
            width: 3,
            colors: ['#6366f1']
        },
        fill: {
            type: 'gradient',
            gradient: {
                shadeIntensity: 1,
                opacityFrom: 0.45,
                opacityTo: 0.05,
                stops: [20, 100, 100, 100]
            }
        },
        colors: ['#6366f1'],
        xaxis: {
            categories: labels,
            labels: {
                style: {
                    colors: '#94a3b8',
                    fontSize: '12px'
                }
            },
            axisBorder: { show: false },
            axisTicks: { show: false },
        },
        yaxis: {
            labels: {
                style: {
                    colors: '#94a3b8',
                    fontSize: '12px'
                }
            }
        },
        grid: {
            borderColor: 'rgba(148, 163, 184, 0.1)',
            strokeDashArray: 4,
        },
        tooltip: {
            theme: 'dark',
            x: { show: true },
        },
        markers: {
            size: 5,
            colors: ['#6366f1'],
            strokeColors: '#fff',
            strokeWidth: 2,
            hover: { size: 7 }
        }
    };

    const series = [{
        name: 'Score',
        data: dataPoints
    }];

    return (
        <div className="w-full h-[300px]">
            <Chart options={options} series={series} type="area" height="100%" />
        </div>
    );
}
