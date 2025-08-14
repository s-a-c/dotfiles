# Flux UI Components Overview

<link rel="stylesheet" href="../../assets/css/styles.css">

## Introduction

Flux UI provides a comprehensive set of UI components for Livewire that are designed to be accessible, responsive, and easy to use. This page provides an overview of the available components and how to use them in your application.

## Basic Components

### Buttons

Flux UI provides a variety of button styles and variants:

```php
<!-- Basic Button -->
<x-flux-button>Click Me</x-flux-button>

<!-- Button Variants -->
<x-flux-button variant="primary">Primary</x-flux-button>
<x-flux-button variant="secondary">Secondary</x-flux-button>
<x-flux-button variant="success">Success</x-flux-button>
<x-flux-button variant="danger">Danger</x-flux-button>
<x-flux-button variant="warning">Warning</x-flux-button>
<x-flux-button variant="info">Info</x-flux-button>

<!-- Button Sizes -->
<x-flux-button size="sm">Small</x-flux-button>
<x-flux-button size="md">Medium</x-flux-button>
<x-flux-button size="lg">Large</x-flux-button>

<!-- Button with Icon -->
<x-flux-button>
    <x-flux-icon name="user" class="mr-2" />
    User Profile
</x-flux-button>

<!-- Loading State -->
<x-flux-button wire:loading.attr="disabled" wire:target="save">
    <span wire:loading.remove wire:target="save">Save</span>
    <span wire:loading wire:target="save">Saving...</span>
</x-flux-button>
```

### Cards

Cards are versatile containers for organizing content:

```php
<x-flux-card>
    <x-flux-card-header>
        <h3 class="text-lg font-medium">Card Title</h3>
    </x-flux-card-header>
    
    <x-flux-card-body>
        <p>This is the card content.</p>
    </x-flux-card-body>
    
    <x-flux-card-footer>
        <x-flux-button>Action</x-flux-button>
    </x-flux-card-footer>
</x-flux-card>
```

### Form Inputs

Flux UI provides a variety of form inputs with built-in validation:

```php
<!-- Text Input -->
<x-flux-input 
    label="Name" 
    wire:model="name" 
    placeholder="Enter your name" 
    helper="Your full name as it appears on your ID."
/>

<!-- Email Input -->
<x-flux-input 
    type="email" 
    label="Email" 
    wire:model="email" 
    placeholder="Enter your email" 
/>

<!-- Password Input -->
<x-flux-input 
    type="password" 
    label="Password" 
    wire:model="password" 
    placeholder="Enter your password" 
/>

<!-- Textarea -->
<x-flux-textarea 
    label="Bio" 
    wire:model="bio" 
    placeholder="Tell us about yourself" 
    rows="4"
/>

<!-- Select -->
<x-flux-select 
    label="Country" 
    wire:model="country" 
    :options="[
        'us' => 'United States',
        'ca' => 'Canada',
        'mx' => 'Mexico',
    ]" 
/>

<!-- Checkbox -->
<x-flux-checkbox 
    label="Subscribe to newsletter" 
    wire:model="subscribe" 
/>

<!-- Radio Group -->
<x-flux-radio-group 
    label="Notification Preference" 
    wire:model="notificationPreference" 
    :options="[
        'email' => 'Email',
        'sms' => 'SMS',
        'push' => 'Push Notification',
    ]" 
/>

<!-- Toggle -->
<x-flux-toggle 
    label="Dark Mode" 
    wire:model="darkMode" 
/>
```

### Tables

Flux UI provides a powerful table component:

```php
<x-flux-table>
    <x-slot name="header">
        <x-flux-table-heading>Name</x-flux-table-heading>
        <x-flux-table-heading>Email</x-flux-table-heading>
        <x-flux-table-heading>Role</x-flux-table-heading>
        <x-flux-table-heading>Actions</x-flux-table-heading>
    </x-slot>
    
    <x-flux-table-row>
        <x-flux-table-cell>John Doe</x-flux-table-cell>
        <x-flux-table-cell>john@example.com</x-flux-table-cell>
        <x-flux-table-cell>Admin</x-flux-table-cell>
        <x-flux-table-cell>
            <x-flux-button size="sm">Edit</x-flux-button>
            <x-flux-button size="sm" variant="danger">Delete</x-flux-button>
        </x-flux-table-cell>
    </x-flux-table-row>
    
    <!-- More rows... -->
</x-flux-table>
```

### Alerts

Display informational messages:

```php
<x-flux-alert variant="success">
    Your profile has been updated successfully.
</x-flux-alert>

<x-flux-alert variant="danger">
    There was an error processing your request.
</x-flux-alert>

<x-flux-alert variant="warning">
    Your subscription will expire in 7 days.
</x-flux-alert>

<x-flux-alert variant="info">
    A new version of the application is available.
</x-flux-alert>
```

### Badges

Display small counts and labels:

```php
<x-flux-badge>New</x-flux-badge>
<x-flux-badge variant="success">Completed</x-flux-badge>
<x-flux-badge variant="danger">Overdue</x-flux-badge>
<x-flux-badge variant="warning">Pending</x-flux-badge>
<x-flux-badge variant="info">In Progress</x-flux-badge>
```

### Modals

Create interactive dialogs:

```php
<x-flux-button wire:click="$set('showModal', true)">
    Open Modal
</x-flux-button>

<x-flux-modal wire:model="showModal">
    <x-slot name="title">
        Confirm Action
    </x-slot>
    
    <div class="p-4">
        <p>Are you sure you want to perform this action?</p>
    </div>
    
    <x-slot name="footer">
        <x-flux-button wire:click="$set('showModal', false)">
            Cancel
        </x-flux-button>
        <x-flux-button variant="primary" wire:click="confirmAction">
            Confirm
        </x-flux-button>
    </x-slot>
</x-flux-modal>
```

## Flux Pro Components

Flux Pro provides additional advanced components for more complex UI requirements.

### Date Picker

```php
<x-flux-pro-datepicker 
    label="Appointment Date" 
    wire:model="appointmentDate" 
/>

<x-flux-pro-daterangepicker 
    label="Vacation Period" 
    wire:model="vacationPeriod" 
/>
```

### File Upload

```php
<x-flux-pro-file-upload 
    label="Profile Picture" 
    wire:model="profilePicture" 
    accept="image/*" 
    :preview="true"
/>

<x-flux-pro-file-upload 
    label="Documents" 
    wire:model="documents" 
    accept=".pdf,.doc,.docx" 
    multiple
/>
```

### Rich Text Editor

```php
<x-flux-pro-rich-text-editor 
    label="Content" 
    wire:model="content" 
/>
```

### Charts

```php
<x-flux-pro-chart 
    type="bar" 
    :data="[
        'labels' => ['January', 'February', 'March'],
        'datasets' => [
            [
                'label' => 'Sales',
                'data' => [1000, 1500, 2000],
                'backgroundColor' => '#4f46e5',
            ],
        ],
    ]" 
    :options="[
        'scales' => [
            'y' => [
                'beginAtZero' => true,
            ],
        ],
    ]"
/>
```

### Data Grid

```php
<x-flux-pro-data-grid 
    :columns="[
        ['key' => 'name', 'label' => 'Name'],
        ['key' => 'email', 'label' => 'Email'],
        ['key' => 'role', 'label' => 'Role'],
    ]" 
    :data="$users" 
    :pagination="true" 
    :searchable="true" 
    :sortable="true"
/>
```

### Toast Notifications

```php
<div>
    <x-flux-button wire:click="showToast">
        Show Toast
    </x-flux-button>
    
    <x-flux-pro-toast />
</div>

<script>
    // In your Livewire component
    public function showToast()
    {
        $this->dispatch('toast', [
            'title' => 'Success',
            'message' => 'Operation completed successfully',
            'type' => 'success',
        ]);
    }
</script>
```

### Autocomplete

```php
<x-flux-pro-autocomplete 
    label="User" 
    wire:model="selectedUser" 
    :options="$users" 
    option-label="name" 
    option-value="id" 
    placeholder="Search for a user..." 
/>
```

## Using Flux UI with Livewire

Flux UI components integrate seamlessly with Livewire. Here's an example of a complete form using Flux UI components:

```php
<div>
    <x-flux-card>
        <x-flux-card-header>
            <h2 class="text-lg font-medium">Create User</h2>
        </x-flux-card-header>
        
        <x-flux-card-body>
            <form wire:submit="createUser" class="space-y-6">
                <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
                    <x-flux-input 
                        label="First Name" 
                        wire:model="firstName" 
                        placeholder="Enter first name" 
                        required 
                    />
                    
                    <x-flux-input 
                        label="Last Name" 
                        wire:model="lastName" 
                        placeholder="Enter last name" 
                        required 
                    />
                </div>
                
                <x-flux-input 
                    type="email" 
                    label="Email" 
                    wire:model="email" 
                    placeholder="Enter email address" 
                    required 
                />
                
                <x-flux-select 
                    label="Role" 
                    wire:model="role" 
                    :options="$roles" 
                    required 
                />
                
                <x-flux-checkbox 
                    label="Active" 
                    wire:model="active" 
                />
                
                <div class="flex items-center gap-4">
                    <x-flux-button type="submit">
                        Create User
                    </x-flux-button>
                    
                    <x-flux-button variant="secondary" wire:click="cancel">
                        Cancel
                    </x-flux-button>
                </div>
            </form>
        </x-flux-card-body>
    </x-flux-card>
    
    <x-flux-pro-toast />
</div>
```

## Customizing Flux UI Components

Flux UI components can be customized to match your application's design:

### Using Tailwind Classes

```php
<x-flux-button class="bg-purple-600 hover:bg-purple-700">
    Custom Button
</x-flux-button>
```

### Using Component Attributes

```php
<x-flux-input 
    label="Custom Input" 
    wire:model="customField" 
    placeholder="Enter value" 
    helper="This is a custom input field."
    leading-icon="user"
    trailing-icon="check"
/>
```

### Creating Component Presets

You can create component presets by publishing the Flux UI configuration and defining your own component presets:

```php
// config/flux.php
return [
    'presets' => [
        'buttons' => [
            'primary' => 'bg-purple-600 hover:bg-purple-700 text-white',
            'secondary' => 'bg-gray-200 hover:bg-gray-300 text-gray-800',
        ],
    ],
];
```

## Next Steps

Now that you understand the basics of Flux UI components, you're ready to use them in your application. Continue to [Installing Flux UI](./070-installing-flux-ui.md) to set up Flux UI in your project.
