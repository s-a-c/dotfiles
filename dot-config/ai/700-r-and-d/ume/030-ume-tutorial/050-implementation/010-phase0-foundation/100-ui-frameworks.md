# UI Framework Overview

<link rel="stylesheet" href="../../assets/css/styles.css">

## Introduction

This tutorial provides implementations for multiple UI approaches. This page explains each approach, its strengths, and when to use it.

<div class="ui-framework-comparison">
    <div class="ui-framework">
        <h3>Livewire with Flux UI</h3>
        <p><strong>Primary Path</strong></p>
        <p>PHP-driven reactivity with pre-built UI components</p>
        <ul>
            <li>Minimal JavaScript</li>
            <li>Familiar Laravel/PHP syntax</li>
            <li>Professional UI components</li>
            <li>Rapid development</li>
        </ul>
    </div>
    <div class="ui-framework">
        <h3>FilamentPHP</h3>
        <p><strong>Admin Interface</strong></p>
        <p>TALL stack admin panel framework</p>
        <ul>
            <li>Resource-based CRUD</li>
            <li>Form builder</li>
            <li>Table builder</li>
            <li>Dashboard widgets</li>
        </ul>
    </div>
    <div class="ui-framework">
        <h3>Inertia.js with React</h3>
        <p><strong>Alternative Path</strong></p>
        <p>SPA experience with React components</p>
        <ul>
            <li>React component ecosystem</li>
            <li>Client-side routing</li>
            <li>Laravel backend</li>
            <li>No API required</li>
        </ul>
    </div>
    <div class="ui-framework">
        <h3>Inertia.js with Vue</h3>
        <p><strong>Alternative Path</strong></p>
        <p>SPA experience with Vue components</p>
        <ul>
            <li>Vue component ecosystem</li>
            <li>Client-side routing</li>
            <li>Laravel backend</li>
            <li>No API required</li>
        </ul>
    </div>
</div>

## Livewire with Flux UI

[Livewire](https://livewire.laravel.com/) is a full-stack framework for Laravel that makes building dynamic interfaces simple, without leaving the comfort of PHP. Livewire provides a way to build dynamic, reactive components using PHP and minimal JavaScript.

[Flux UI](https://fluxui.dev/) is a collection of pre-built UI components for Livewire that provides a professional, accessible user interface out of the box. Flux UI components are designed to work seamlessly with Livewire, allowing you to create a polished user interface with minimal effort.

### Key Features of Livewire with Flux UI

- **PHP-Driven Reactivity**: Build reactive UIs without writing JavaScript
- **Pre-Built UI Components**: Professional, accessible components
- **Familiar Syntax**: Use Laravel/PHP syntax you already know
- **Rapid Development**: Build complex UIs quickly
- **Progressive Enhancement**: Works with or without JavaScript
- **Accessibility**: Built with accessibility in mind

### Example: Flux UI Button Component

```php
<x-flux-button>Click Me</x-flux-button>
```

### Example: Flux UI Card Component

```php
<x-flux-card>
    <x-flux-card-header>
        <h3 class="text-lg font-medium">Card Title</h3>
    </x-flux-card-header>
    <x-flux-card-body>
        <p>Card content goes here.</p>
    </x-flux-card-body>
    <x-flux-card-footer>
        <x-flux-button>Action</x-flux-button>
    </x-flux-card-footer>
</x-flux-card>
```

### Example: Flux UI Form Components

```php
<form wire:submit="save">
    <x-flux-input 
        label="Name" 
        wire:model="name" 
        placeholder="Enter your name" 
    />
    
    <x-flux-textarea 
        label="Bio" 
        wire:model="bio" 
        placeholder="Tell us about yourself" 
    />
    
    <x-flux-select 
        label="Country" 
        wire:model="country" 
        :options="$countries" 
    />
    
    <x-flux-checkbox 
        label="Subscribe to newsletter" 
        wire:model="subscribe" 
    />
    
    <x-flux-button type="submit">Save</x-flux-button>
</form>
```

### Example: Flux Pro Components

Flux Pro provides additional advanced components:

```php
<x-flux-pro-datepicker 
    label="Appointment Date" 
    wire:model="appointmentDate" 
/>

<x-flux-pro-file-upload 
    label="Profile Picture" 
    wire:model="profilePicture" 
    accept="image/*" 
/>

<x-flux-pro-rich-text-editor 
    label="Content" 
    wire:model="content" 
/>

<x-flux-pro-chart 
    type="bar" 
    :data="$chartData" 
    :options="$chartOptions" 
/>
```

## FilamentPHP

[FilamentPHP](https://filamentphp.com/) is a collection of tools for rapidly building beautiful TALL stack (Tailwind, Alpine, Laravel, Livewire) applications. We'll use Filament primarily for the admin interface.

### Key Features of FilamentPHP

- **Resource Management**: CRUD operations for your models
- **Form Builder**: Build complex forms with minimal code
- **Table Builder**: Create powerful data tables
- **Dashboard Widgets**: Display key metrics and data
- **Access Control**: Role-based permissions
- **Theme Customization**: Customize the look and feel

### Example: Filament Resource

```php
use App\Models\User;
use Filament\Resources\Resource;
use Filament\Resources\Forms\Form;
use Filament\Resources\Tables\Table;
use Filament\Forms\Components\TextInput;
use Filament\Tables\Columns\TextColumn;

class UserResource extends Resource
{
    protected static ?string $model = User::class;
    
    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                TextInput::make('name')->required(),
                TextInput::make('email')->email()->required(),
                // ...
            ]);
    }
    
    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('name'),
                TextColumn::make('email'),
                // ...
            ]);
    }
}
```

## Inertia.js with React/Vue

[Inertia.js](https://inertiajs.com/) allows you to create fully client-side rendered, single-page apps, without the complexity that comes with modern SPAs. It does this by leveraging existing server-side frameworks (like Laravel) and client-side frameworks (like React or Vue).

### Key Features of Inertia.js

- **No API Required**: Use your Laravel routes and controllers
- **Client-Side Routing**: SPA-like navigation without page reloads
- **Data Persistence**: Maintain state between page visits
- **Progressive Enhancement**: Works with or without JavaScript
- **SEO Friendly**: Server-side rendering options

### Example: Inertia with React

```jsx
// resources/js/Pages/Profile/Edit.jsx
import { useState } from 'react';
import { Inertia } from '@inertiajs/inertia';
import Layout from '@/Layouts/AuthenticatedLayout';

export default function Edit({ auth, user }) {
    const [values, setValues] = useState({
        name: user.name,
        email: user.email,
    });

    function handleChange(e) {
        setValues(values => ({
            ...values,
            [e.target.id]: e.target.value,
        }));
    }

    function handleSubmit(e) {
        e.preventDefault();
        Inertia.put(route('profile.update'), values);
    }

    return (
        <Layout auth={auth}>
            <div className="py-12">
                <div className="max-w-7xl mx-auto sm:px-6 lg:px-8">
                    <div className="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                        <div className="p-6 bg-white border-b border-gray-200">
                            <form onSubmit={handleSubmit}>
                                <div className="mb-6">
                                    <label htmlFor="name" className="block mb-2 text-sm font-medium text-gray-900">
                                        Name
                                    </label>
                                    <input
                                        id="name"
                                        value={values.name}
                                        onChange={handleChange}
                                        className="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5"
                                    />
                                </div>
                                <div className="mb-6">
                                    <label htmlFor="email" className="block mb-2 text-sm font-medium text-gray-900">
                                        Email
                                    </label>
                                    <input
                                        id="email"
                                        value={values.email}
                                        onChange={handleChange}
                                        className="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5"
                                    />
                                </div>
                                <button
                                    type="submit"
                                    className="text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-sm w-full sm:w-auto px-5 py-2.5 text-center"
                                >
                                    Save
                                </button>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        </Layout>
    );
}
```

### Example: Inertia with Vue

```vue
<!-- resources/js/Pages/Profile/Edit.vue -->
<script setup>
import { ref } from 'vue';
import { useForm } from '@inertiajs/vue3';
import AuthenticatedLayout from '@/Layouts/AuthenticatedLayout.vue';

const props = defineProps({
    auth: Object,
    user: Object,
});

const form = useForm({
    name: props.user.name,
    email: props.user.email,
});

function submit() {
    form.put(route('profile.update'));
}
</script>

<template>
    <AuthenticatedLayout :auth="auth">
        <div class="py-12">
            <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
                <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                    <div class="p-6 bg-white border-b border-gray-200">
                        <form @submit.prevent="submit">
                            <div class="mb-6">
                                <label for="name" class="block mb-2 text-sm font-medium text-gray-900">
                                    Name
                                </label>
                                <input
                                    id="name"
                                    v-model="form.name"
                                    class="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5"
                                />
                            </div>
                            <div class="mb-6">
                                <label for="email" class="block mb-2 text-sm font-medium text-gray-900">
                                    Email
                                </label>
                                <input
                                    id="email"
                                    v-model="form.email"
                                    class="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5"
                                />
                            </div>
                            <button
                                type="submit"
                                class="text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-sm w-full sm:w-auto px-5 py-2.5 text-center"
                            >
                                Save
                            </button>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </AuthenticatedLayout>
</template>
```

## Choosing the Right Approach

In this tutorial, we'll primarily use **Livewire with Flux UI** for the user-facing interface and **FilamentPHP** for the admin interface. However, we'll provide conceptual implementations for **Inertia.js with React** and **Inertia.js with Vue** as alternative approaches.

Choose the approach that best fits your team's skills and project requirements:

- **Livewire with Flux UI**: If you prefer PHP and want to minimize JavaScript
- **FilamentPHP**: For admin interfaces and rapid CRUD development
- **Inertia.js with React**: If your team has React experience
- **Inertia.js with Vue**: If your team has Vue experience

## Next Steps

Now that we understand the different UI approaches, let's complete our foundation setup with the [First Git Commit](./090-git-commit.md).
