<?php

namespace App\Http\Controllers\Desktop;

use App\Http\Controllers\Controller;
use App\Models\AppRelease;
use App\Models\Device;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Inertia\Inertia;
use Inertia\Response;

/**
 * Desktop installer releases (Admin). /app/version serves the highest active release, so
 * deactivating the newest one rolls every PC back to the previous active version.
 */
class AppReleaseController extends Controller
{
    public function index(): Response
    {
        $this->authorize('viewAny', AppRelease::class);

        $latest = AppRelease::latestActive();
        $versions = Device::query()->whereNotNull('app_version')->get(['id', 'name', 'app_version'])->groupBy('app_version');

        $releases = AppRelease::query()->with('publisher:id,name')->get()
            ->sort(fn (AppRelease $a, AppRelease $b) => version_compare($b->version, $a->version))
            ->values()
            ->map(fn (AppRelease $r) => [
                'id' => $r->id,
                'version' => $r->version,
                'notes' => $r->notes,
                'mandatory' => $r->mandatory,
                'is_active' => $r->is_active,
                'is_latest' => $latest?->id === $r->id,
                'file_size' => $r->file_size,
                'sha256' => $r->sha256,
                'publisher' => $r->publisher?->name,
                'created_at' => $r->created_at?->toIso8601String(),
                'devices' => ($versions[$r->version] ?? collect())->pluck('name')->values(),
            ]);

        return Inertia::render('desktop/releases', [
            'releases' => $releases,
            'otherVersions' => $versions->keys()->diff($releases->pluck('version'))->mapWithKeys(fn ($v) => [$v => $versions[$v]->pluck('name')])->all(),
            'minVersion' => AppRelease::minVersion(),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $this->authorize('create', AppRelease::class);

        $data = $request->validate([
            'version' => ['required', 'string', 'regex:/^\d+\.\d+\.\d+$/', 'unique:app_releases,version'],
            'notes' => ['nullable', 'string', 'max:5000'],
            'mandatory' => ['nullable', 'boolean'],
            'is_active' => ['nullable', 'boolean'],
            'file' => ['required', 'file', 'extensions:exe', 'max:512000'],
        ]);

        $file = $request->file('file');
        $directory = AppRelease::DIRECTORY.'/'.$data['version'];
        $name = 'mynine-setup-'.$data['version'].'.exe';

        $path = Storage::disk(AppRelease::DISK)->putFileAs($directory, $file, $name);
        abort_unless($path, 500, 'Faylni saqlab bo\'lmadi.');

        $absolute = Storage::disk(AppRelease::DISK)->path($path);

        AppRelease::create([
            'version' => $data['version'],
            'notes' => $data['notes'] ?? null,
            'mandatory' => $request->boolean('mandatory'),
            'is_active' => $request->has('is_active') ? $request->boolean('is_active') : true,
            'file_path' => $path,
            'file_size' => filesize($absolute),
            'sha256' => hash_file('sha256', $absolute),
            'published_by' => $request->user()->id,
        ]);

        return back()->with('success', "{$data['version']} versiya yuklandi.");
    }

    public function update(Request $request, AppRelease $appRelease): RedirectResponse
    {
        $this->authorize('update', $appRelease);

        $data = $request->validate([
            'notes' => ['sometimes', 'nullable', 'string', 'max:5000'],
            'mandatory' => ['sometimes', 'boolean'],
            'is_active' => ['sometimes', 'boolean'],
        ]);

        $appRelease->update($data);

        return back()->with('success', 'Reliz yangilandi.');
    }

    public function destroy(AppRelease $appRelease): RedirectResponse
    {
        $this->authorize('delete', $appRelease);

        if ($appRelease->file_path) {
            Storage::disk(AppRelease::DISK)->deleteDirectory(dirname($appRelease->file_path));
        }
        $appRelease->delete();

        return back()->with('success', "Reliz o'chirildi.");
    }
}
