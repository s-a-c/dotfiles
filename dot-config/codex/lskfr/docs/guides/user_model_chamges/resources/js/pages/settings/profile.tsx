import { FormEventHandler, useRef, useEffect } from 'react';
import { Head, useForm, usePage } from '@inertiajs/react';
import { useLivewire } from 'use-livewire';
import { AppLayout } from '@/layouts/app-layout';
import { SettingsLayout } from '@/layouts/settings-layout';
import { HeadingSmall } from '@/components/heading-small';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { FormMessage } from '@/components/form-message';
import { type SharedData } from '@/types';

const breadcrumbs = [
    { title: 'Settings', href: route('settings') },
    { title: 'Profile', href: route('profile.edit') },
];

type ProfileForm = {
    given_name: string;
    family_name: string;
    email: string;
    avatar?: string;
}

export default function Profile({ mustVerifyEmail, status }: { mustVerifyEmail: boolean; status?: string }) {
    const { auth } = usePage<SharedData>().props;
    const livewire = useLivewire();

    const { data, setData, patch, errors, processing, recentlySuccessful } = useForm<Required<ProfileForm>>({
        given_name: auth.user.given_name,
        family_name: auth.user.family_name,
        email: auth.user.email,
        avatar: auth.user.avatar,
    });

    // Listen for avatar updates from Livewire
    useEffect(() => {
        const unsubscribe = livewire.on('avatarUpdated', () => {
            // Refresh the page to show the updated avatar
            window.location.reload();
        });

        return () => {
            unsubscribe();
        };
    }, [livewire]);

    const submit: FormEventHandler = (e) => {
        e.preventDefault();

        patch(route('profile.update'), {
            preserveScroll: true,
        });
    };

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title="Profile settings" />

            <SettingsLayout>
                <div className="space-y-6">
                    <HeadingSmall title="Profile information" description="Update your name and email address" />

                    {/* Avatar Upload Component */}
                    <div className="mb-6">
                        <h3 className="text-lg font-medium mb-4">Profile Picture</h3>
                        <div className="flex items-center space-x-4">
                            <livewire:upload-avatar />
                        </div>
                    </div>

                    <form onSubmit={submit} className="space-y-6">
                        <div className="grid gap-4 sm:grid-cols-2">
                            <div className="grid gap-2">
                                <Label htmlFor="given_name">First name</Label>
                                <Input
                                    id="given_name"
                                    value={data.given_name}
                                    onChange={(e) => setData('given_name', e.target.value)}
                                    required
                                />
                                <FormMessage message={errors.given_name} />
                            </div>

                            <div className="grid gap-2">
                                <Label htmlFor="family_name">Last name</Label>
                                <Input
                                    id="family_name"
                                    value={data.family_name}
                                    onChange={(e) => setData('family_name', e.target.value)}
                                    required
                                />
                                <FormMessage message={errors.family_name} />
                            </div>
                        </div>

                        <div className="grid gap-2">
                            <Label htmlFor="email">Email</Label>
                            <Input
                                id="email"
                                type="email"
                                value={data.email}
                                onChange={(e) => setData('email', e.target.value)}
                                required
                            />
                            <FormMessage message={errors.email} />
                        </div>



                        {mustVerifyEmail && auth.user.email_verified_at === null && (
                            <div>
                                <p className="text-sm text-muted-foreground mt-2">
                                    Your email address is unverified.
                                    <button
                                        type="button"
                                        className="text-primary underline rounded-md outline-none hover:text-primary/80 focus:text-primary/80 ml-1"
                                        onClick={() => {
                                            // Send verification email
                                        }}
                                    >
                                        Click here to re-send the verification email.
                                    </button>
                                </p>

                                {status === 'verification-link-sent' && (
                                    <div className="text-sm font-medium text-green-600 mt-2">
                                        A new verification link has been sent to your email address.
                                    </div>
                                )}
                            </div>
                        )}

                        <div className="flex items-center gap-4">
                            <Button type="submit" disabled={processing}>Save</Button>

                            {recentlySuccessful && (
                                <p className="text-sm text-muted-foreground">Saved.</p>
                            )}
                        </div>
                    </form>
                </div>
            </SettingsLayout>
        </AppLayout>
    );
}
