// resources/js/components/TextareaEditor.tsx
import React, { useEffect, useRef, useState } from "react";
import { Editor } from "@tinymce/tinymce-react";
import InputError from "@/components/input-error";


import type { Editor as TinyMCEEditorInstance } from "tinymce";

interface TextareaEditorProps {
    value?: string;
    onChange?: (content: string) => void;
    error?: string | null;
    height?: number | string;
    className?: string;
}

export default function TextareaEditor({
    value = "",
    onChange = () => { },
    error = null,
    height = 500,
    className,
}: TextareaEditorProps) {
    const editorRef = useRef<TinyMCEEditorInstance | null>(null);
    const [mounted, setMounted] = useState(false);

    useEffect(() => {
        setMounted(true);
    }, []);

    useEffect(() => {
        if (!mounted) return;

        const POPUP_SELECTOR =
            ".tox-tinymce-aux, .tox-dialog, .moxman-window, .tam-assetmanager-root";

        function stopIfPopup(e: Event) {
            const target = e.target as HTMLElement | null;
            if (target?.closest && target.closest(POPUP_SELECTOR)) {
                e.stopPropagation();
            }
        }

        document.addEventListener("pointerdown", stopIfPopup, true);
        document.addEventListener("mousedown", stopIfPopup, true);
        document.addEventListener("touchstart", stopIfPopup, true);

        return () => {
            document.removeEventListener("pointerdown", stopIfPopup, true);
            document.removeEventListener("mousedown", stopIfPopup, true);
            document.removeEventListener("touchstart", stopIfPopup, true);
        };
    }, [mounted]);

    if (!mounted) {
        return (
            <div className={className}>
                <textarea
                    defaultValue={value}
                    onChange={(e) => onChange(e.target.value)}
                    style={{ minHeight: height }}
                    className="w-full rounded border p-2"
                />
                {error && <InputError message={error} />}
            </div>
        );
    }

    return (
        <div className={className}>
            <style>{`
                .tox-tinymce-aux, .tox-dialog, .moxman-window, .tam-assetmanager-root {
                    z-index: 2147483646 !important;
                    pointer-events: auto !important;
                }
                .tox.tox-fullscreen { z-index: 2147483645 !important; }
                .tox-promotion, .tox-statusbar__branding, .tox-notification--warning, .tox-notification {
                    display: none !important;
                }
            `}</style>

            <Editor
                licenseKey="gpl"
                tinymceScriptSrc="/vendor/tinymce/tinymce.min.js"
                onInit={(_evt, editor) => (editorRef.current = editor)}
                value={value}
                onEditorChange={(content) => onChange(content)}
                init={{
                    // @ts-expect-error -- license_key is accepted by TinyMCE but missing from its typings
                    license_key: 'gpl',
                    promotion: false,
                    branding: false,
                    base_url: '/vendor/tinymce',
                    suffix: '.min',
                    height,
                    menubar: "file edit view insert format tools table help",
                    convert_urls: true,
                    relative_urls: false,
                    remove_script_host: true,
                    document_base_url: '/',
                    plugins: [
                        "advlist",
                        "anchor",
                        "autolink",
                        "charmap",
                        "code",
                        "codesample",
                        "directionality",
                        "emoticons",
                        "fullscreen",
                        "help",
                        "image",
                        "importcss",
                        "insertdatetime",
                        "link",
                        "lists",
                        "media",
                        "preview",
                        "searchreplace",
                        "table",
                        "visualblocks",
                        "visualchars",
                        "wordcount",
                    ],
                    toolbar:
                        "undo redo | blocks fontfamily fontsize | " +
                        "bold italic underline strikethrough forecolor backcolor | " +
                        "link image media table emoticons | alignleft aligncenter " +
                        "alignright alignjustify | bullist numlist outdent indent | " +
                        "removeformat | code fullscreen preview | help",
                    content_style: "body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 16px; line-height: 1.6; color: #1e293b; padding: 12px; }",
                }}
            />

            {error && <InputError message={error} />}
        </div>
    );
}
