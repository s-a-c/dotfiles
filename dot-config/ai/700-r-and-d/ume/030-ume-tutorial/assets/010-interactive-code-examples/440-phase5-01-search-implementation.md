# Search Implementation

:::interactive-code
title: Implementing Advanced Search with Laravel Scout
description: This example demonstrates how to implement a comprehensive search system using Laravel Scout with custom search engines and advanced features.
language: php
editable: true
code: |
  <?php
  
  namespace App\Models;
  
  use Illuminate\Database\Eloquent\Model;
  use Laravel\Scout\Searchable;
  
  class Task extends Model
  {
      use Searchable;
      
      protected $fillable = [
          'title',
          'description',
          'status',
          'priority',
          'due_date',
          'assigned_to',
          'team_id',
          'tags',
      ];
      
      protected $casts = [
          'due_date' => 'datetime',
          'tags' => 'array',
      ];
      
      /**
       * Get the indexable data array for the model.
       *
       * @return array
       */
      public function toSearchableArray(): array
      {
          // Load relationships
          $this->load(['team', 'assignedTo', 'comments']);
          
          // Get basic model data
          $array = $this->toArray();
          
          // Customize the data array to include related data
          $array['team_name'] = $this->team->name ?? null;
          $array['assigned_to_name'] = $this->assignedTo->name ?? null;
          
          // Add comments content
          $array['comments'] = $this->comments->pluck('content')->implode(' ');
          
          // Add formatted date for better searching
          $array['due_date_formatted'] = $this->due_date ? $this->due_date->format('Y-m-d') : null;
          
          // Remove unnecessary fields
          unset($array['created_at'], $array['updated_at']);
          
          return $array;
      }
      
      /**
       * Get the value used to index the model.
       *
       * @return mixed
       */
      public function getScoutKey()
      {
          return $this->id;
      }
      
      /**
       * Get the key name used to index the model.
       *
       * @return mixed
       */
      public function getScoutKeyName()
      {
          return 'id';
      }
      
      /**
       * Determine if the model should be searchable.
       *
       * @return bool
       */
      public function shouldBeSearchable()
      {
          // Only index tasks that aren't deleted
          return !$this->trashed();
      }
      
      /**
       * Get the team that owns the task.
       */
      public function team()
      {
          return $this->belongsTo(Team::class);
      }
      
      /**
       * Get the user that the task is assigned to.
       */
      public function assignedTo()
      {
          return $this->belongsTo(User::class, 'assigned_to');
      }
      
      /**
       * Get the comments for the task.
       */
      public function comments()
      {
          return $this->hasMany(Comment::class);
      }
  }
  
  namespace App\Services;
  
  use App\Models\Task;
  use App\Models\User;
  use Illuminate\Pagination\LengthAwarePaginator;
  use Illuminate\Support\Facades\Auth;
  
  class SearchService
  {
      /**
       * Search for tasks.
       *
       * @param string $query
       * @param array $filters
       * @param int $perPage
       * @return LengthAwarePaginator
       */
      public function searchTasks(string $query, array $filters = [], int $perPage = 15): LengthAwarePaginator
      {
          $user = Auth::user();
          
          // Start with a base query
          $search = Task::search($query);
          
          // Apply team filter if provided
          if (isset($filters['team_id'])) {
              $search->where('team_id', $filters['team_id']);
          } else {
              // Only search tasks from teams the user belongs to
              $teamIds = $user->teams->pluck('id')->toArray();
              $search->whereIn('team_id', $teamIds);
          }
          
          // Apply status filter
          if (isset($filters['status'])) {
              $search->where('status', $filters['status']);
          }
          
          // Apply priority filter
          if (isset($filters['priority'])) {
              $search->where('priority', $filters['priority']);
          }
          
          // Apply assignee filter
          if (isset($filters['assigned_to'])) {
              $search->where('assigned_to', $filters['assigned_to']);
          }
          
          // Apply due date filter
          if (isset($filters['due_date_from'])) {
              $search->where('due_date', '>=', $filters['due_date_from']);
          }
          
          if (isset($filters['due_date_to'])) {
              $search->where('due_date', '<=', $filters['due_date_to']);
          }
          
          // Apply tag filter
          if (isset($filters['tag'])) {
              $search->whereIn('tags', [$filters['tag']]);
          }
          
          // Apply sorting
          if (isset($filters['sort_by'])) {
              $direction = $filters['sort_direction'] ?? 'asc';
              $search->orderBy($filters['sort_by'], $direction);
          }
          
          // Get paginated results
          return $search->paginate($perPage);
      }
      
      /**
       * Search for users.
       *
       * @param string $query
       * @param array $filters
       * @param int $perPage
       * @return LengthAwarePaginator
       */
      public function searchUsers(string $query, array $filters = [], int $perPage = 15): LengthAwarePaginator
      {
          $user = Auth::user();
          
          // Start with a base query
          $search = User::search($query);
          
          // Apply team filter if provided
          if (isset($filters['team_id'])) {
              $teamId = $filters['team_id'];
              $search->whereHas('teams', function ($query) use ($teamId) {
                  $query->where('teams.id', $teamId);
              });
          }
          
          // Apply role filter
          if (isset($filters['role'])) {
              $search->where('role', $filters['role']);
          }
          
          // Get paginated results
          return $search->paginate($perPage);
      }
      
      /**
       * Perform a global search across multiple models.
       *
       * @param string $query
       * @param int $perPage
       * @return array
       */
      public function globalSearch(string $query, int $perPage = 5): array
      {
          $user = Auth::user();
          $teamIds = $user->teams->pluck('id')->toArray();
          
          // Search tasks
          $tasks = Task::search($query)
              ->whereIn('team_id', $teamIds)
              ->take($perPage)
              ->get();
          
          // Search users (only from teams the user belongs to)
          $users = User::search($query)
              ->whereHas('teams', function ($query) use ($teamIds) {
                  $query->whereIn('teams.id', $teamIds);
              })
              ->take($perPage)
              ->get();
          
          // Return combined results
          return [
              'tasks' => $tasks,
              'users' => $users,
          ];
      }
  }
  
  namespace App\Http\Controllers;
  
  use App\Services\SearchService;
  use Illuminate\Http\Request;
  
  class SearchController extends Controller
  {
      protected $searchService;
      
      public function __construct(SearchService $searchService)
      {
          $this->searchService = $searchService;
          $this->middleware('auth');
      }
      
      /**
       * Search for tasks.
       */
      public function searchTasks(Request $request)
      {
          $request->validate([
              'query' => 'required|string|min:2',
              'team_id' => 'nullable|exists:teams,id',
              'status' => 'nullable|string',
              'priority' => 'nullable|string',
              'assigned_to' => 'nullable|exists:users,id',
              'due_date_from' => 'nullable|date',
              'due_date_to' => 'nullable|date',
              'tag' => 'nullable|string',
              'sort_by' => 'nullable|string|in:title,status,priority,due_date,created_at',
              'sort_direction' => 'nullable|string|in:asc,desc',
              'per_page' => 'nullable|integer|min:5|max:100',
          ]);
          
          $query = $request->input('query');
          $filters = $request->except(['query', 'per_page']);
          $perPage = $request->input('per_page', 15);
          
          $results = $this->searchService->searchTasks($query, $filters, $perPage);
          
          return response()->json($results);
      }
      
      /**
       * Search for users.
       */
      public function searchUsers(Request $request)
      {
          $request->validate([
              'query' => 'required|string|min:2',
              'team_id' => 'nullable|exists:teams,id',
              'role' => 'nullable|string',
              'per_page' => 'nullable|integer|min:5|max:100',
          ]);
          
          $query = $request->input('query');
          $filters = $request->except(['query', 'per_page']);
          $perPage = $request->input('per_page', 15);
          
          $results = $this->searchService->searchUsers($query, $filters, $perPage);
          
          return response()->json($results);
      }
      
      /**
       * Perform a global search.
       */
      public function globalSearch(Request $request)
      {
          $request->validate([
              'query' => 'required|string|min:2',
              'per_page' => 'nullable|integer|min:5|max:20',
          ]);
          
          $query = $request->input('query');
          $perPage = $request->input('per_page', 5);
          
          $results = $this->searchService->globalSearch($query, $perPage);
          
          return response()->json($results);
      }
  }
  
  namespace App\Providers;
  
  use Illuminate\Support\ServiceProvider;
  use Laravel\Scout\EngineManager;
  use App\Search\CustomSearchEngine;
  
  class AppServiceProvider extends ServiceProvider
  {
      /**
       * Register any application services.
       */
      public function register(): void
      {
          //
      }
      
      /**
       * Bootstrap any application services.
       */
      public function boot(): void
      {
          // Register custom Scout engine
          resolve(EngineManager::class)->extend('custom', function () {
              return new CustomSearchEngine();
          });
      }
  }
  
  namespace App\Search;
  
  use Laravel\Scout\Engines\Engine;
  use Illuminate\Database\Eloquent\Collection;
  
  class CustomSearchEngine extends Engine
  {
      /**
       * Update the given model in the index.
       *
       * @param  \Illuminate\Database\Eloquent\Collection  $models
       * @return void
       */
      public function update($models)
      {
          // Implementation for updating models in the search index
          // This would integrate with your custom search solution
      }
      
      /**
       * Remove the given model from the index.
       *
       * @param  \Illuminate\Database\Eloquent\Collection  $models
       * @return void
       */
      public function delete($models)
      {
          // Implementation for removing models from the search index
      }
      
      /**
       * Perform the given search on the engine.
       *
       * @param  \Laravel\Scout\Builder  $builder
       * @return mixed
       */
      public function search($builder)
      {
          // Implementation for searching the index
          // This would integrate with your custom search solution
      }
      
      /**
       * Perform the given search on the engine.
       *
       * @param  \Laravel\Scout\Builder  $builder
       * @param  int  $perPage
       * @param  int  $page
       * @return mixed
       */
      public function paginate($builder, $perPage, $page)
      {
          // Implementation for paginated search
      }
      
      /**
       * Pluck and return the primary keys of the given results.
       *
       * @param  mixed  $results
       * @return \Illuminate\Support\Collection
       */
      public function mapIds($results)
      {
          // Implementation for mapping search results to model IDs
      }
      
      /**
       * Map the given results to instances of the given model.
       *
       * @param  \Laravel\Scout\Builder  $builder
       * @param  mixed  $results
       * @param  \Illuminate\Database\Eloquent\Model  $model
       * @return \Illuminate\Database\Eloquent\Collection
       */
      public function map($builder, $results, $model)
      {
          // Implementation for mapping search results to model instances
      }
      
      /**
       * Get the total count from a raw result returned by the engine.
       *
       * @param  mixed  $results
       * @return int
       */
      public function getTotalCount($results)
      {
          // Implementation for getting the total count of search results
      }
      
      /**
       * Flush all of the model's records from the engine.
       *
       * @param  \Illuminate\Database\Eloquent\Model  $model
       * @return void
       */
      public function flush($model)
      {
          // Implementation for flushing all records of a model from the index
      }
  }
  
  // Example configuration (config/scout.php)
  
  /*
  return [
      'driver' => env('SCOUT_DRIVER', 'meilisearch'),
      
      'queue' => env('SCOUT_QUEUE', true),
      
      'after_commit' => false,
      
      'chunk' => [
          'searchable' => 500,
          'unsearchable' => 500,
      ],
      
      'soft_delete' => true,
      
      'identify' => env('SCOUT_IDENTIFY', false),
      
      'algolia' => [
          'id' => env('ALGOLIA_APP_ID', ''),
          'secret' => env('ALGOLIA_SECRET', ''),
      ],
      
      'meilisearch' => [
          'host' => env('MEILISEARCH_HOST', 'http://localhost:7700'),
          'key' => env('MEILISEARCH_KEY', null),
          'index-settings' => [
              // MeiliSearch index settings...
              Task::class => [
                  'filterableAttributes' => [
                      'team_id',
                      'status',
                      'priority',
                      'assigned_to',
                      'due_date',
                      'tags',
                  ],
                  'sortableAttributes' => [
                      'title',
                      'status',
                      'priority',
                      'due_date',
                      'created_at',
                  ],
                  'searchableAttributes' => [
                      'title',
                      'description',
                      'team_name',
                      'assigned_to_name',
                      'comments',
                      'tags',
                  ],
              ],
              User::class => [
                  'filterableAttributes' => [
                      'role',
                      'teams.id',
                  ],
                  'sortableAttributes' => [
                      'name',
                      'email',
                      'created_at',
                  ],
                  'searchableAttributes' => [
                      'name',
                      'email',
                      'profile.bio',
                  ],
              ],
          ],
      ],
  ];
  */
  
  // Example client-side JavaScript for search interface
  
  /*
  // Task search component
  class TaskSearch {
      constructor() {
          this.searchForm = document.getElementById('task-search-form');
          this.searchInput = document.getElementById('task-search-input');
          this.resultsContainer = document.getElementById('task-search-results');
          this.filtersContainer = document.getElementById('task-search-filters');
          this.paginationContainer = document.getElementById('task-search-pagination');
          
          this.currentPage = 1;
          this.perPage = 15;
          this.filters = {};
          
          this.setupEventListeners();
      }
      
      setupEventListeners() {
          // Search form submission
          this.searchForm.addEventListener('submit', (e) => {
              e.preventDefault();
              this.currentPage = 1;
              this.search();
          });
          
          // Search input (for live search)
          this.searchInput.addEventListener('input', debounce(() => {
              if (this.searchInput.value.length >= 2) {
                  this.currentPage = 1;
                  this.search();
              }
          }, 300));
          
          // Filter changes
          this.filtersContainer.querySelectorAll('select, input').forEach(element => {
              element.addEventListener('change', () => {
                  this.currentPage = 1;
                  this.updateFilters();
                  this.search();
              });
          });
      }
      
      updateFilters() {
          this.filters = {};
          
          // Get values from filter form elements
          const teamSelect = document.getElementById('filter-team');
          if (teamSelect && teamSelect.value) {
              this.filters.team_id = teamSelect.value;
          }
          
          const statusSelect = document.getElementById('filter-status');
          if (statusSelect && statusSelect.value) {
              this.filters.status = statusSelect.value;
          }
          
          const prioritySelect = document.getElementById('filter-priority');
          if (prioritySelect && prioritySelect.value) {
              this.filters.priority = prioritySelect.value;
          }
          
          const assigneeSelect = document.getElementById('filter-assignee');
          if (assigneeSelect && assigneeSelect.value) {
              this.filters.assigned_to = assigneeSelect.value;
          }
          
          const dueDateFrom = document.getElementById('filter-due-date-from');
          if (dueDateFrom && dueDateFrom.value) {
              this.filters.due_date_from = dueDateFrom.value;
          }
          
          const dueDateTo = document.getElementById('filter-due-date-to');
          if (dueDateTo && dueDateTo.value) {
              this.filters.due_date_to = dueDateTo.value;
          }
          
          const tagInput = document.getElementById('filter-tag');
          if (tagInput && tagInput.value) {
              this.filters.tag = tagInput.value;
          }
          
          const sortBySelect = document.getElementById('sort-by');
          if (sortBySelect && sortBySelect.value) {
              this.filters.sort_by = sortBySelect.value;
          }
          
          const sortDirectionSelect = document.getElementById('sort-direction');
          if (sortDirectionSelect && sortDirectionSelect.value) {
              this.filters.sort_direction = sortDirectionSelect.value;
          }
      }
      
      search() {
          const query = this.searchInput.value;
          
          if (query.length < 2) {
              this.resultsContainer.innerHTML = '<p>Please enter at least 2 characters to search</p>';
              return;
          }
          
          this.resultsContainer.innerHTML = '<p>Searching...</p>';
          
          // Build query parameters
          const params = new URLSearchParams({
              query: query,
              page: this.currentPage,
              per_page: this.perPage,
              ...this.filters
          });
          
          // Perform search request
          fetch(`/api/search/tasks?${params.toString()}`)
              .then(response => response.json())
              .then(data => {
                  this.renderResults(data);
              })
              .catch(error => {
                  console.error('Error performing search:', error);
                  this.resultsContainer.innerHTML = '<p>An error occurred while searching</p>';
              });
      }
      
      renderResults(data) {
          if (data.total === 0) {
              this.resultsContainer.innerHTML = '<p>No results found</p>';
              this.paginationContainer.innerHTML = '';
              return;
          }
          
          // Render results
          let html = '<div class="search-results-list">';
          
          data.data.forEach(task => {
              html += `
                  <div class="search-result-item">
                      <h3><a href="/.ai/tasks/${task.id}">${task.title}</a></h3>
                      <div class="search-result-meta">
                          <span class="status status-${task.status}">${task.status}</span>
                          <span class="priority priority-${task.priority}">${task.priority}</span>
                          <span class="due-date">${task.due_date_formatted || 'No due date'}</span>
                      </div>
                      <p>${task.description.substring(0, 150)}${task.description.length > 150 ? '...' : ''}</p>
                      <div class="search-result-footer">
                          <span class="team">Team: ${task.team_name}</span>
                          <span class="assignee">Assigned to: ${task.assigned_to_name || 'Unassigned'}</span>
                      </div>
                  </div>
              `;
          });
          
          html += '</div>';
          
          this.resultsContainer.innerHTML = html;
          
          // Render pagination
          this.renderPagination(data);
      }
      
      renderPagination(data) {
          const totalPages = Math.ceil(data.total / data.per_page);
          
          if (totalPages <= 1) {
              this.paginationContainer.innerHTML = '';
              return;
          }
          
          let html = '<div class="pagination">';
          
          // Previous page button
          if (data.current_page > 1) {
              html += `<button class="pagination-prev" data-page="${data.current_page - 1}">Previous</button>`;
          } else {
              html += `<button class="pagination-prev" disabled>Previous</button>`;
          }
          
          // Page numbers
          html += '<div class="pagination-pages">';
          
          for (let i = 1; i <= totalPages; i++) {
              if (
                  i === 1 ||
                  i === totalPages ||
                  (i >= data.current_page - 2 && i <= data.current_page + 2)
              ) {
                  const activeClass = i === data.current_page ? 'active' : '';
                  html += `<button class="pagination-page ${activeClass}" data-page="${i}">${i}</button>`;
              } else if (
                  i === data.current_page - 3 ||
                  i === data.current_page + 3
              ) {
                  html += '<span class="pagination-ellipsis">...</span>';
              }
          }
          
          html += '</div>';
          
          // Next page button
          if (data.current_page < totalPages) {
              html += `<button class="pagination-next" data-page="${data.current_page + 1}">Next</button>`;
          } else {
              html += `<button class="pagination-next" disabled>Next</button>`;
          }
          
          html += '</div>';
          
          this.paginationContainer.innerHTML = html;
          
          // Add event listeners to pagination buttons
          this.paginationContainer.querySelectorAll('button[data-page]').forEach(button => {
              button.addEventListener('click', () => {
                  this.currentPage = parseInt(button.dataset.page);
                  this.search();
                  
                  // Scroll back to top of results
                  this.resultsContainer.scrollIntoView({ behavior: 'smooth' });
              });
          });
      }
  }
  
  // Initialize search
  const taskSearch = new TaskSearch();
  
  // Debounce function for search input
  function debounce(func, wait) {
      let timeout;
      return function() {
          const context = this;
          const args = arguments;
          clearTimeout(timeout);
          timeout = setTimeout(() => {
              func.apply(context, args);
          }, wait);
      };
  }
  */
explanation: |
  This example demonstrates a comprehensive search implementation using Laravel Scout:
  
  1. **Model Configuration**: Making models searchable with Laravel Scout:
     - Customizing the searchable data array
     - Including related data in the search index
     - Controlling when models should be searchable
  
  2. **Search Service**: A dedicated service for search operations:
     - Searching tasks with filters and pagination
     - Searching users with filters and pagination
     - Performing global search across multiple models
  
  3. **Search Controller**: API endpoints for search operations:
     - Task search endpoint with validation
     - User search endpoint with validation
     - Global search endpoint
  
  4. **Custom Search Engine**: Extending Laravel Scout with a custom search engine:
     - Implementing the required Engine interface methods
     - Allowing for integration with any search backend
  
  5. **Scout Configuration**: Configuring Laravel Scout for optimal search:
     - Setting up filterable attributes for filtering
     - Setting up sortable attributes for sorting
     - Setting up searchable attributes for relevance
  
  6. **Client-Side Implementation**: A JavaScript component for the search interface:
     - Handling search input and form submission
     - Managing filters and pagination
     - Rendering search results and pagination
  
  Key features of the implementation:
  
  - **Advanced Filtering**: Filtering by team, status, priority, assignee, due date, and tags
  - **Sorting Options**: Sorting by various attributes in ascending or descending order
  - **Pagination**: Paginating search results for better performance
  - **Real-Time Search**: Debounced input for real-time search as the user types
  - **Related Data**: Including related data in the search index for better results
  - **Security**: Ensuring users can only search for data they have access to
  
  In a real Laravel application:
  - You would implement a real search backend like Meilisearch or Elasticsearch
  - You would add more sophisticated relevance scoring
  - You would implement search analytics to track popular searches
  - You would add search suggestions and autocomplete
  - You would implement caching for frequent searches
challenges:
  - Implement search suggestions and autocomplete
  - Add support for fuzzy search to handle typos
  - Create a search analytics dashboard to track popular searches
  - Implement search result highlighting to show matching terms
  - Add support for natural language queries (e.g., "tasks due tomorrow")
:::
