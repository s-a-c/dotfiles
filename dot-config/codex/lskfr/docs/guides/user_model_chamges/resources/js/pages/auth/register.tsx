import { FormEventHandler, useEffect } from 'react';
import { Head, Link, useForm } from '@inertiajs/react';
import { AuthLayout } from '@/layouts/auth-layout';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { FormMessage } from '@/components/form-message';

export default function Register() {
    const { data, setData, post, processing, errors, reset } = useForm({
        given_name: '',
        family_name: '',
        email: '',
        password: '',
        password_confirmation: '',
    });

    useEffect(() => {
        return () => {
            reset('password', 'password_confirmation');
        };
    }, []);

    const submit: FormEventHandler = (e) => {
        e.preventDefault();

        post(route('register'));
    };

    return (
        <AuthLayout>
            <Head title="Register" />

            <div className="flex flex-col space-y-2 text-center">
                <h1 className="text-2xl font-semibold tracking-tight">Create an account</h1>
                <p className="text-sm text-muted-foreground">Enter your information below to create your account</p>
            </div>

            <div className="grid gap-6">
                <form onSubmit={submit}>
                    <div className="grid gap-4">
                        <div className="grid gap-4 sm:grid-cols-2">
                            <div className="grid gap-2">
                                <Label htmlFor="given_name">First name</Label>
                                <Input
                                    id="given_name"
                                    name="given_name"
                                    value={data.given_name}
                                    className="block w-full"
                                    autoComplete="given-name"
                                    onChange={(e) => setData('given_name', e.target.value)}
                                    required
                                />
                                <FormMessage message={errors.given_name} />
                            </div>

                            <div className="grid gap-2">
                                <Label htmlFor="family_name">Last name</Label>
                                <Input
                                    id="family_name"
                                    name="family_name"
                                    value={data.family_name}
                                    className="block w-full"
                                    autoComplete="family-name"
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
                                name="email"
                                value={data.email}
                                className="block w-full"
                                autoComplete="username"
                                onChange={(e) => setData('email', e.target.value)}
                                required
                            />
                            <FormMessage message={errors.email} />
                        </div>

                        {/* Avatar Upload Component */}
                        <div className="grid gap-2 mb-4">
                            <livewire:register-avatar />
                        </div>

                        <div className="grid gap-2">
                            <Label htmlFor="password">Password</Label>
                            <Input
                                id="password"
                                type="password"
                                name="password"
                                value={data.password}
                                className="block w-full"
                                autoComplete="new-password"
                                onChange={(e) => setData('password', e.target.value)}
                                required
                            />
                            <FormMessage message={errors.password} />
                        </div>

                        <div className="grid gap-2">
                            <Label htmlFor="password_confirmation">Confirm Password</Label>
                            <Input
                                id="password_confirmation"
                                type="password"
                                name="password_confirmation"
                                value={data.password_confirmation}
                                className="block w-full"
                                autoComplete="new-password"
                                onChange={(e) => setData('password_confirmation', e.target.value)}
                                required
                            />
                            <FormMessage message={errors.password_confirmation} />
                        </div>

                        <Button className="w-full" disabled={processing}>
                            Register
                        </Button>
                    </div>
                </form>

                <div className="text-center text-sm">
                    Already have an account?{' '}
                    <Link
                        href={route('login')}
                        className="text-primary underline underline-offset-4 hover:text-primary/80"
                    >
                        Sign in
                    </Link>
                </div>
            </div>
        </AuthLayout>
    );
}
