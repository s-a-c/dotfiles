<?php

namespace Tests\Unit;

use App\Http\Controllers\CodeExecutionController;
use Illuminate\Http\Request;
use old\TestCase;

class CodeExecutionControllerTest extends TestCase
{
    /**
     * Test code execution with valid code.
     *
     * @return void
     */
    public function test_execute_with_valid_code()
    {
        $request = new Request([
            'code' => '<?php echo "Hello, World!";',
            'language' => 'php'
        ]);

        $controller = new CodeExecutionController();
        $response = $controller->execute($request);

        $this->assertEquals(200, $response->getStatusCode());
        $this->assertJson($response->getContent());
        
        $data = json_decode($response->getContent(), true);
        $this->assertTrue($data['success']);
        $this->assertEquals('Hello, World!', trim($data['output']));
    }

    /**
     * Test code execution with invalid code.
     *
     * @return void
     */
    public function test_execute_with_invalid_code()
    {
        $request = new Request([
            'code' => '<?php echo $undefinedVariable;',
            'language' => 'php'
        ]);

        $controller = new CodeExecutionController();
        $response = $controller->execute($request);

        $this->assertEquals(200, $response->getStatusCode());
        $this->assertJson($response->getContent());
        
        $data = json_decode($response->getContent(), true);
        $this->assertFalse($data['success']);
        $this->assertStringContainsString('Undefined variable', $data['output']);
    }

    /**
     * Test code execution with dangerous code.
     *
     * @return void
     */
    public function test_execute_with_dangerous_code()
    {
        $request = new Request([
            'code' => '<?php system("ls");',
            'language' => 'php'
        ]);

        $controller = new CodeExecutionController();
        $response = $controller->execute($request);

        $this->assertEquals(200, $response->getStatusCode());
        $this->assertJson($response->getContent());
        
        $data = json_decode($response->getContent(), true);
        $this->assertFalse($data['success']);
        $this->assertStringContainsString('system', $data['output']);
    }
}
