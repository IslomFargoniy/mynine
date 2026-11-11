<?php

namespace App\Http\Controllers;

use App\Models\Folder;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Inertia\Inertia;

/**
 * Test Bank: practice tests grouped by folder.
 *
 * Students and Reception see active folders with active + open practice tests (and only modules
 * that have content). Admins see every folder and every practice test (inactive / closed ones are
 * marked in the UI) and manage folders and tests on the same page. Mock Bank tests never appear.
 */
class AllTestController extends Controller
{
    public function index(Request $request)
    {
        $isAdmin = Auth::user()->hasRole('Admin');
        $per_page = $request->per_page === 'all' ? 100 : max(1, min((int) ($request->per_page ?? 10), 100));

        $folder = Folder::with([
            'tests' => function ($query) use ($isAdmin) {
                $query->practice()
                    ->with([
                        'types' => function ($query) use ($isAdmin) {
                            if (! $isAdmin) {
                                $query->whereHas('parts');
                            }
                            $query->orderBy('type_id');
                        },
                    ])
                    ->withCount('attempts')
                    ->orderBy('id', 'asc');

                if (! $isAdmin) {
                    $query->where('active', 1)->where('open', 1);
                }
            },
        ]);

        if (! $isAdmin) {
            // Admins also see empty folders (to add tests); everyone else only folders with something to start.
            $folder->where('active', 1)
                ->whereHas('tests', fn ($query) => $query->practice()->where('active', 1)->where('open', 1));
        }

        if ($request->search) {
            $folder->where(function ($query) use ($request) {
                $query->where('name', 'like', "%$request->search%")
                    ->orWhere('comment', 'like', "%$request->search%");
            });
        }

        if ($request->from && $request->to) {
            $folder->whereBetween('created_at', [$request->from, $request->to]);
        }

        if ($request->folder_id) {
            $folder->where('id', $request->folder_id);
        }

        $folder = $folder->select('id', 'name', 'comment', 'active', 'user_id', 'created_at', 'updated_at')
            ->orderBy('id', 'asc')
            ->paginate($per_page);

        $folders = Folder::select('id', 'name')
            ->when(! $isAdmin, fn ($query) => $query->where('active', 1))
            ->orderBy('id')
            ->limit(100)
            ->get();

        return Inertia::render('test-bank/index', [
            'folder' => $folder,
            'folders' => $folders,
            'isAdmin' => $isAdmin,
            'filters' => $request->only(['search', 'folder_id', 'from', 'to', 'per_page']),
        ]);
    }
}
