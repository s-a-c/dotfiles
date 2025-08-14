<?php
/**
 * PSR-3 Compatible Logger
 *
 * Provides comprehensive logging functionality with multiple verbosity levels,
 * colored output, and structured logging support for debugging and monitoring.
 *
 * @package SAC\ValidateLinks\Utils
 */

declare(strict_types=1);

namespace SAC\ValidateLinks\Utils;

/**
 * Logger with PSR-3 compatibility and enhanced features
 *
 * Supports multiple verbosity levels, colored console output, and structured
 * logging for comprehensive debugging and monitoring capabilities.
 */
final class Logger
{
    /**
     * Verbosity levels
     */
    public const QUIET = 0;
    public const NORMAL = 1;
    public const VERBOSE = 2;
    public const DEBUG = 3;

    /**
     * ANSI color codes
     */
    private const COLORS = [
        'reset' => "\033[0m",
        'red' => "\033[31m",
        'green' => "\033[32m",
        'yellow' => "\033[33m",
        'blue' => "\033[34m",
        'magenta' => "\033[35m",
        'cyan' => "\033[36m",
        'white' => "\033[37m",
        'bold' => "\033[1m",
        'dim' => "\033[2m",
    ];

    private int $verbosity = self::NORMAL;
    private bool $useColors = true;
    private mixed $output;

    public function __construct(mixed $output = null)
    {
        $this->output = $output ?? STDERR;

        // Detect if colors should be used
        $this->useColors = $this->shouldUseColors();
    }

    /**
     * Set the verbosity level
     *
     * @param int $level Verbosity level
     */
    public function setVerbosity(int $level): void
    {
        $this->verbosity = max(0, min(3, $level));
    }

    /**
     * Get the current verbosity level
     *
     * @return int Current verbosity level
     */
    public function getVerbosity(): int
    {
        return $this->verbosity;
    }

    /**
     * Disable colored output
     */
    public function disableColors(): void
    {
        $this->useColors = false;
    }

    /**
     * Log an emergency message
     *
     * @param string $message Message to log
     * @param array<string, mixed> $context Additional context
     */
    public function emergency(string $message, array $context = []): void
    {
        $this->log('emergency', $message, $context);
    }

    /**
     * Log an alert message
     *
     * @param string $message Message to log
     * @param array<string, mixed> $context Additional context
     */
    public function alert(string $message, array $context = []): void
    {
        $this->log('alert', $message, $context);
    }

    /**
     * Log a critical message
     *
     * @param string $message Message to log
     * @param array<string, mixed> $context Additional context
     */
    public function critical(string $message, array $context = []): void
    {
        $this->log('critical', $message, $context);
    }

    /**
     * Log an error message
     *
     * @param string $message Message to log
     * @param array<string, mixed> $context Additional context
     */
    public function error(string $message, array $context = []): void
    {
        $this->log('error', $message, $context);
    }

    /**
     * Log a warning message
     *
     * @param string $message Message to log
     * @param array<string, mixed> $context Additional context
     */
    public function warning(string $message, array $context = []): void
    {
        $this->log('warning', $message, $context);
    }

    /**
     * Log a notice message
     *
     * @param string $message Message to log
     * @param array<string, mixed> $context Additional context
     */
    public function notice(string $message, array $context = []): void
    {
        $this->log('notice', $message, $context);
    }

    /**
     * Log an info message
     *
     * @param string $message Message to log
     * @param array<string, mixed> $context Additional context
     */
    public function info(string $message, array $context = []): void
    {
        $this->log('info', $message, $context);
    }

    /**
     * Log a debug message
     *
     * @param string $message Message to log
     * @param array<string, mixed> $context Additional context
     */
    public function debug(string $message, array $context = []): void
    {
        $this->log('debug', $message, $context);
    }

    /**
     * Log a message with the given level
     *
     * @param string $level Log level
     * @param string $message Message to log
     * @param array<string, mixed> $context Additional context
     */
    public function log(string $level, string $message, array $context = []): void
    {
        $requiredVerbosity = $this->getLevelVerbosity($level);

        if ($this->verbosity < $requiredVerbosity) {
            return;
        }

        $formattedMessage = $this->formatMessage($level, $message, $context);
        $this->write($formattedMessage);
    }

    /**
     * Get the required verbosity level for a log level
     *
     * @param string $level Log level
     * @return int Required verbosity
     */
    private function getLevelVerbosity(string $level): int
    {
        return match ($level) {
            'emergency', 'alert', 'critical', 'error' => self::QUIET,
            'warning', 'notice', 'info' => self::NORMAL,
            'debug' => self::DEBUG,
            default => self::VERBOSE,
        };
    }

    /**
     * Format a log message
     *
     * @param string $level Log level
     * @param string $message Message
     * @param array<string, mixed> $context Context data
     * @return string Formatted message
     */
    private function formatMessage(string $level, string $message, array $context): string
    {
        $timestamp = date('Y-m-d H:i:s');
        $levelUpper = strtoupper($level);

        // Interpolate context variables in message
        $interpolatedMessage = $this->interpolate($message, $context);

        // Add color if enabled
        $coloredLevel = $this->colorizeLevel($levelUpper);

        $formatted = "[{$timestamp}] {$coloredLevel}: {$interpolatedMessage}";

        // Add context if in debug mode and context is not empty
        if ($this->verbosity >= self::DEBUG && !empty($context)) {
            $contextJson = json_encode($context, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
            $formatted .= "\nContext: {$contextJson}";
        }

        return $formatted;
    }

    /**
     * Interpolate context values into message placeholders
     *
     * @param string $message Message with placeholders
     * @param array<string, mixed> $context Context values
     * @return string Interpolated message
     */
    private function interpolate(string $message, array $context): string
    {
        $replace = [];

        foreach ($context as $key => $value) {
            if (is_scalar($value) || (is_object($value) && method_exists($value, '__toString'))) {
                $replace["{{$key}}"] = (string) $value;
            }
        }

        return strtr($message, $replace);
    }

    /**
     * Colorize log level text
     *
     * @param string $level Log level
     * @return string Colorized level
     */
    private function colorizeLevel(string $level): string
    {
        if (!$this->useColors) {
            return $level;
        }

        $color = match ($level) {
            'EMERGENCY', 'ALERT', 'CRITICAL' => 'red',
            'ERROR' => 'red',
            'WARNING' => 'yellow',
            'NOTICE' => 'cyan',
            'INFO' => 'green',
            'DEBUG' => 'dim',
            default => 'white',
        };

        return $this->colorize($level, $color);
    }

    /**
     * Apply color to text
     *
     * @param string $text Text to colorize
     * @param string $color Color name
     * @return string Colorized text
     */
    private function colorize(string $text, string $color): string
    {
        if (!$this->useColors || !isset(self::COLORS[$color])) {
            return $text;
        }

        return self::COLORS[$color] . $text . self::COLORS['reset'];
    }

    /**
     * Determine if colors should be used
     *
     * @return bool True if colors should be used
     */
    private function shouldUseColors(): bool
    {
        // Check if NO_COLOR environment variable is set
        if (getenv('NO_COLOR') !== false) {
            return false;
        }

        // Check if output is a TTY
        if (is_resource($this->output)) {
            return stream_isatty($this->output);
        }

        // Default to true for STDERR
        return $this->output === STDERR && stream_isatty(STDERR);
    }

    /**
     * Write message to output
     *
     * @param string $message Message to write
     */
    private function write(string $message): void
    {
        if (is_resource($this->output)) {
            fwrite($this->output, $message . PHP_EOL);
        } else {
            echo $message . PHP_EOL;
        }
    }
}
