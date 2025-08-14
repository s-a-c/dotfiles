export interface User {
    id: number;
    name: string; // Computed from given_name + family_name
    given_name: string;
    family_name: string;
    email: string;
    avatar?: string; // URL to avatar image
    avatar_url?: string; // Computed property that returns media URL or avatar field
    avatar_thumb_url?: string; // URL to thumbnail version of avatar
    slug: string;
    ulid: string;
    email_verified_at: string | null;
    created_at: string;
    updated_at: string;
    [key: string]: unknown; // This allows for additional properties
}
