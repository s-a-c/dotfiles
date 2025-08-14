# Metrics Collection Plan for Interactive Examples

This document outlines the strategy for collecting usage metrics from the interactive examples system.

## Metrics Collection Objectives

1. **Understand User Behavior**: Gain insights into how users interact with interactive examples
2. **Identify Popular Content**: Determine which examples are most useful to users
3. **Detect Usability Issues**: Identify areas where users struggle
4. **Measure Educational Impact**: Assess how effectively examples help users learn
5. **Guide Future Development**: Inform decisions about new features and improvements

## Key Metrics to Collect

### User Engagement Metrics

| Metric | Description | Collection Method | Storage | Analysis Frequency |
|--------|-------------|-------------------|---------|-------------------|
| Page Views | Number of views for pages with interactive examples | Page tracking | Analytics DB | Daily |
| Example Interactions | Number of interactions with each example | Event tracking | Analytics DB | Daily |
| Time on Example | Time spent on each interactive example | Session tracking | Analytics DB | Weekly |
| Scroll Depth | How far users scroll through examples | Scroll tracking | Analytics DB | Weekly |
| Return Rate | Percentage of users who return to examples | User tracking | Analytics DB | Monthly |

### Code Execution Metrics

| Metric | Description | Collection Method | Storage | Analysis Frequency |
|--------|-------------|-------------------|---------|-------------------|
| Execution Count | Number of times code is executed | API logging | Application DB | Daily |
| Execution Success Rate | Percentage of successful code executions | API logging | Application DB | Daily |
| Execution Time | Time taken to execute code | Performance logging | Application DB | Weekly |
| Code Modifications | How users modify example code | Diff tracking | Application DB | Weekly |
| Error Types | Types of errors encountered | Error logging | Application DB | Weekly |

### Feature Usage Metrics

| Metric | Description | Collection Method | Storage | Analysis Frequency |
|--------|-------------|-------------------|---------|-------------------|
| Button Clicks | Usage of specific buttons (run, reset, etc.) | Event tracking | Analytics DB | Daily |
| Keyboard Shortcuts | Usage of keyboard shortcuts | Event tracking | Analytics DB | Weekly |
| Fullscreen Mode | Usage of fullscreen mode | Event tracking | Analytics DB | Weekly |
| Copy Code | Frequency of copying code | Event tracking | Analytics DB | Weekly |
| Format Code | Usage of code formatting | Event tracking | Analytics DB | Weekly |

### Learning Metrics

| Metric | Description | Collection Method | Storage | Analysis Frequency |
|--------|-------------|-------------------|---------|-------------------|
| Challenge Attempts | Number of attempts at challenges | Event tracking | Analytics DB | Weekly |
| Challenge Completion | Percentage of challenges completed | Event tracking | Analytics DB | Weekly |
| Example Progression | Movement through sequential examples | User tracking | Analytics DB | Monthly |
| Time to Success | Time taken to successfully complete examples | Event tracking | Analytics DB | Monthly |
| Help Usage | Frequency of accessing hints or help | Event tracking | Analytics DB | Weekly |

### Technical Metrics

| Metric | Description | Collection Method | Storage | Analysis Frequency |
|--------|-------------|-------------------|---------|-------------------|
| Browser Types | Distribution of browsers used | User agent tracking | Analytics DB | Monthly |
| Device Types | Distribution of devices used | User agent tracking | Analytics DB | Monthly |
| Screen Sizes | Distribution of screen sizes | Viewport tracking | Analytics DB | Monthly |
| Load Times | Time to load and initialize examples | Performance tracking | Analytics DB | Weekly |
| Error Rates | Client-side errors encountered | Error logging | Application DB | Daily |

## Data Collection Implementation

### Frontend Tracking

```javascript
// Example implementation of frontend tracking
function trackEvent(category, action, label, value) {
  // Send to analytics service
  analytics.trackEvent({
    category: category,
    action: action,
    label: label,
    value: value
  });
  
  // Also log to application for internal analytics
  fetch('/api/track-event', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
    },
    body: JSON.stringify({
      category: category,
      action: action,
      label: label,
      value: value,
      page: window.location.pathname,
      timestamp: new Date().toISOString()
    })
  });
}

// Track code execution
function trackCodeExecution(exampleId, success, executionTime) {
  trackEvent(
    'Code Execution',
    success ? 'Success' : 'Error',
    exampleId,
    executionTime
  );
}

// Track button clicks
function trackButtonClick(buttonType, exampleId) {
  trackEvent(
    'Button Click',
    buttonType,
    exampleId
  );
}

// Track time spent on example
let startTime = Date.now();
window.addEventListener('beforeunload', function() {
  const timeSpent = (Date.now() - startTime) / 1000;
  trackEvent(
    'Time Spent',
    'Example',
    window.location.pathname,
    timeSpent
  );
});
```

### Backend Tracking

```php
// Example implementation of backend tracking
public function trackEvent(Request $request)
{
    // Validate the request
    $validated = $request->validate([
        'category' => 'required|string',
        'action' => 'required|string',
        'label' => 'required|string',
        'value' => 'nullable|numeric',
        'page' => 'required|string',
        'timestamp' => 'required|date'
    ]);
    
    // Store the event
    Event::create([
        'user_id' => Auth::id() ?? null,
        'session_id' => $request->session()->getId(),
        'category' => $validated['category'],
        'action' => $validated['action'],
        'label' => $validated['label'],
        'value' => $validated['value'] ?? null,
        'page' => $validated['page'],
        'timestamp' => $validated['timestamp'],
        'ip_address' => $request->ip(),
        'user_agent' => $request->userAgent()
    ]);
    
    return response()->json(['success' => true]);
}
```

## Data Storage

### Database Schema

```sql
-- Events table for tracking user interactions
CREATE TABLE events (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NULL,
    session_id VARCHAR(255) NOT NULL,
    category VARCHAR(50) NOT NULL,
    action VARCHAR(50) NOT NULL,
    label VARCHAR(255) NOT NULL,
    value DOUBLE NULL,
    page VARCHAR(255) NOT NULL,
    timestamp DATETIME NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    user_agent TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_session_id (session_id),
    INDEX idx_category_action (category, action),
    INDEX idx_timestamp (timestamp)
);

-- Code executions table for tracking code execution
CREATE TABLE code_executions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NULL,
    session_id VARCHAR(255) NOT NULL,
    example_id VARCHAR(50) NOT NULL,
    code TEXT NOT NULL,
    result TEXT NULL,
    success BOOLEAN NOT NULL,
    execution_time DOUBLE NOT NULL,
    error_message TEXT NULL,
    timestamp DATETIME NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_session_id (session_id),
    INDEX idx_example_id (example_id),
    INDEX idx_timestamp (timestamp),
    INDEX idx_success (success)
);
```

### Data Retention

- **Raw Event Data**: 90 days
- **Aggregated Daily Data**: 1 year
- **Aggregated Monthly Data**: 5 years
- **Anonymized Data**: Indefinite

## Data Analysis

### Regular Reports

1. **Daily Dashboard**
   - Total interactions
   - Success/error rates
   - Most active examples
   - Error trends

2. **Weekly Analysis**
   - User engagement patterns
   - Feature usage breakdown
   - Performance metrics
   - Error analysis

3. **Monthly Review**
   - Long-term trends
   - User behavior analysis
   - Content effectiveness
   - Improvement recommendations

### Custom Analysis

1. **User Journey Analysis**
   - Track user progression through examples
   - Identify common paths and drop-off points
   - Measure learning curve

2. **Code Modification Analysis**
   - Analyze how users modify example code
   - Identify common patterns and mistakes
   - Measure creativity and experimentation

3. **Error Pattern Analysis**
   - Identify common errors
   - Correlate errors with user characteristics
   - Develop targeted improvements

## Privacy Considerations

### Data Collection Principles

1. **Minimization**: Collect only necessary data
2. **Purpose Limitation**: Use data only for stated purposes
3. **Storage Limitation**: Retain data only as long as needed
4. **Transparency**: Clearly communicate data collection practices
5. **User Control**: Provide options to opt out where appropriate

### Personal Data Handling

- **IP Addresses**: Anonymized after 30 days
- **User Agents**: Used only for browser/device statistics
- **User IDs**: Pseudonymized for analysis
- **Session IDs**: Used to connect related events without identifying users

### Compliance Measures

- **Privacy Policy**: Clear disclosure of data collection practices
- **Consent Management**: Implementation of consent mechanisms
- **Data Access**: Process for users to access their data
- **Data Deletion**: Process for users to request data deletion
- **Data Protection Impact Assessment**: Regular assessment of privacy risks

## Implementation Timeline

### Phase 1: Basic Metrics (Day 1)

- Implement page view tracking
- Set up basic event tracking
- Configure error logging
- Create daily dashboard

### Phase 2: Enhanced Metrics (Week 1)

- Implement detailed event tracking
- Set up code execution tracking
- Configure performance monitoring
- Create weekly reports

### Phase 3: Advanced Metrics (Month 1)

- Implement user journey tracking
- Set up learning metrics
- Configure custom analysis
- Create monthly review process

## Responsible Team

| Role | Responsibilities | Contact |
|------|------------------|---------|
| Analytics Lead | Overall metrics strategy | email@example.com |
| Frontend Developer | Frontend tracking implementation | email@example.com |
| Backend Developer | Backend tracking implementation | email@example.com |
| Data Analyst | Data analysis and reporting | email@example.com |
| Privacy Officer | Privacy compliance | email@example.com |
