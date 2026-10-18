<?php

namespace App\Http\Controllers;

use App\Services\BlogRepository;

class BlogController extends Controller
{
    public function __construct(private readonly BlogRepository $blog) {}

    public function index()
    {
        return view('seo.blog.index', [
            'articles' => $this->blog->all(),
        ]);
    }

    public function show(string $slug)
    {
        $article = $this->blog->find($slug);
        abort_unless($article, 404);

        return view('seo.blog.show', [
            'article' => $article,
            'related' => $this->blog->related($article),
        ]);
    }
}
