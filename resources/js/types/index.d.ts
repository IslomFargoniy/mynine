import { LucideIcon } from 'lucide-react';
import type { Config } from 'ziggy-js';

export interface Auth {
    user: User;
    roles: Role[];
}

export interface Role {
    id: number;
    name: string;
}


export interface BreadcrumbItem {
    title: string;
    href: string;
}

export interface NavGroup {
    title: string;
    items: NavItem[];
}

export interface NavItem {
    title: string;
    href: string;
    icon?: LucideIcon | null;
    isActive?: boolean;
}

export interface SharedData {
    name: string;
    phone: string;
    quote: { message: string; author: string };
    auth: Auth;
    ziggy: Config & { location: string };
    sidebarOpen: boolean;
    flash: {
        success: string | null;
        error: string | null;
        warning: string | null;
        info: string | null;
    };

    [key: string]: unknown;
}

export interface SearchData {
    search?: string;
    per_page?: number | string;
    page?: number;
    total?: number;
    worker_id?: number;
    branch_id?: number;
    firm_id?: number;
    from?: string;
    to?: string;
    teacher_id?: number | string;
    user_id?: number | string;
    mock_id?: number | string;
    test_id?: number | string;
    folder_id?: number | string;
    role?: string;
    status?: string;

    [key: string]: any; // Allow dynamic keys
}


export interface Link {
    active: string;
    label: string;
    url: string;
}

export interface UserPaginate {
    data: User[];
    search: string;
    per_page: number;
    from: number;
    to: number;
    total: number;
    current_page: number;
    last_page: number;
    links: Link[];
}

export interface User {
    id: number;
    name: string;
    username: string;
    google_id: string;
    ref_telegram_id?: string;
    github_id?: string;
    create_test_limit?: number;
    telegram_id: string;
    email: string;
    phone: string;
    password: string;
    avatar: string;
    email_verified_at: string | null;
    roles?: Role[];
    attempts_count?: number;
    attempts_count_this_month?: number;
    last_attempt?: Attempt;
    attempts?: Attempt[];
    user_firms?: UserFirm[];
    created_at: string,
    updated_at: string,

    [key: string]: unknown;
}

export interface Firm {
    id: number;
    name: string;
    comment: string;
    created_at: string;
    updated_at: string;
}

export interface UserFirm {
    id: number;
    user_id: number;
    firm_id: number;
    role: string;
    firm?: Firm;
    user?: User;
}

export interface Role {
    id: number;
    name: string;
    guard_name: string;
    created_at: string;
    updated_at: string;
}

export interface Folder {
    id: number;
    name: string;
    comment: string;
    active: number;
    created_at: string;
    updated_at: string;
    tests: Test[];
}

export interface FolderPaginate {
    data: Folder[];        // Array of Folder
    search: string;
    per_page: number;
    from: number;
    to: number;
    total: number;
    current_page: number;
    last_page: number;
    links: Link[];         // Array of Link
}

export interface Test {
    id: number;
    name: string;
    comment: string;
    audio_path: string;
    playtime_seconds: number;
    active: number;
    open: number;
    attempts_count: number;
    created_at: string;
    updated_at: string;
    types: TestType[];
    folder: Folder;
}

export interface TestPaginate {
    data: Test[];
    search: string;
    per_page: number;
    from: number;
    to: number;
    total: number;
    current_page: number;
    last_page: number;
    links: Link[];
}

export interface TestType {
    id: number;
    test_id: number;
    type_id: number;
    created_at: string;
    updated_at: string;
    type: Type;
    test: Test;
    parts: Part[];
}

export interface Type {
    id: number;
    name: string;
    minute: number;
    created_at: string;
    updated_at: string;
}


export interface Part {
    id: number;
    test_type_id: number;
    order?: number;
    name: string;
    textarea: string;
    audio_path: string;
    minute: number;
    comment: string;
    created_at: string;
    updated_at: string;
    sections: Section[];
    test_type: TestType;
    attempt_part?: AttemptPart;
}

export interface QuestionType {
    id: number;
    name: string;
    type: string;
    input_type: string;
    created_at: string;
    updated_at: string;
}

export interface Section {
    id: number;
    part_id: number;
    question_type_id: number;
    textarea: string;
    from_option: string;
    to_option: string;
    created_at: string;
    updated_at: string;
    question_type: QuestionType;
    questions: Question[];
    options: Option[];
    /** Present only in exam payloads for drag_and_drop sections (server-built, neutral ids). */
    drag_options?: { id: string; label: string }[];
}

export interface Question {
    id: number;
    section_id: number;
    is_correct_count?: number;
    textarea: string;
    /** Hidden while an exam is in progress; present in review / editor payloads. */
    answer_text?: string | null;
    options: Option[];
    section: Section;
    attempt_answer?: AttemptAnswer;
}

export interface Option {
    id: number;
    question_id: number;
    textarea: string;
    /** Hidden while an exam is in progress. */
    is_correct?: number | boolean;
}


export interface Mock {
    id: number;
    name: string;
    comment: string;
    started_at: string;
    finished_at: string;

    test_id: number;
    user_id: number;
    test: Test;
    user: User;

    slug: string;
    active: number;
    created_at: string;
    updated_at: string;
}

export interface MockPaginate {
    data: Mock[];        // Array of Folder
    search: string;
    per_page: number;
    from: number;
    to: number;
    total: number;
    current_page: number;
    last_page: number;
    links: Link[];         // Array of Link
}


export interface Attempt {
    id: number;
    name: string;
    mock_id: number;
    user_id: number;
    test_id: number;
    started_at: string;
    finished_at: string;
    status: number;
    tab_switch_count?: number;
    user: User;
    mock: Mock;
    test: Test;
    mock_student?: { id: number; name: string };
    mockStudent?: { id: number; name: string };
    attempt_parts: AttemptPart[];
    attempt_types: AttemptType[];
}


export interface AttemptType {
    id: number;
    attempt_id: number;
    type_id: number;
    score: number;
    comment: string;
    started_at: string;
    finished_at: string;
    is_correct_count: number;
    type: Type;
}


export interface AttemptPart {
    id: number;
    attempt_id: number;
    part_id: number;
    started_at: string;
    finished_at: string;
    part?: Part;
}


export interface AttemptPaginate {
    data: Attempt[];        // Array of Folder
    search: string;
    per_page: number;
    from: number;
    to: number;
    total: number;
    current_page: number;
    last_page: number;
    links: Link[];         // Array of Link
}

export interface AttemptAnswer {
    id: number;
    attempt_part_id: number;
    question_id: number;
    answer_text: string;
    audio_path: string;
    transcript: string;
    review_note: string;
    review_note_ai: string;
    is_correct: number;
    score: number;
    created_at: string;
    updated_at: string;
    question: Question;
    attempt_answer_options: AttemptAnswerOptions[];
}

export interface AttemptAnswerOptions {
    attempt_answer_id: number;
    option_id: number;
    created_at: string;
    updated_at: string;
    option: Option;
}

export interface StatItem {
    day_date: string;
    items_count: number;
    unique_users_count?: number;
}

export interface HourlyStatItem {
    hour: number;
    items_count: number;
}

export interface WeeklyStatItem {
    weekday: number;
    items_count: number;
}









