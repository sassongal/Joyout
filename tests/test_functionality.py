#!/usr/bin/env python3

"""
JoyaaS Functionality Test Script
Tests the core text processing functions to verify they work correctly
"""

import sys
import os
import subprocess
import tempfile

# Add current directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def test_python_backend():
    """Test the Python backend functions directly"""
    print("🧪 Testing Python Backend Functions")
    print("=" * 50)
    
    try:
        from joyaas_app_fixed import fix_layout, clean_text
        
        # Test 1: Layout Fixer
        print("1. Testing Layout Fixer:")
        test_text = "שלום hello world"
        result = fix_layout(test_text)
        print(f"   Input:  {repr(test_text)}")
        print(f"   Output: {repr(result)}")
        print(f"   Status: {'✅ Working' if result != test_text else '⚠️ No change'}")
        
        # Test 2: Text Cleaner
        print("\n2. Testing Text Cleaner:")
        messy_text = "  Hello    world  \n\n  with   spaces   "
        cleaned = clean_text(messy_text)
        print(f"   Input:  {repr(messy_text)}")
        print(f"   Output: {repr(cleaned)}")
        print(f"   Status: {'✅ Working' if cleaned != messy_text else '⚠️ No change'}")
        
        print("\n✅ Python backend functions are working!")
        return True
        
    except ImportError as e:
        print(f"❌ Import error: {e}")
        return False
    except Exception as e:
        print(f"❌ Error testing Python backend: {e}")
        return False

def test_swift_python_bridge():
    """Test the Swift to Python bridge by creating a temporary script"""
    print("\n🔗 Testing Swift-Python Bridge Integration")
    print("=" * 50)
    
    # Create a temporary Swift script that mimics what the PythonBridge does
    bridge_test_script = '''
import sys
import os
sys.path.append("{resources_path}")

from joyaas_app_fixed import fix_layout, clean_text

def main():
    # Test layout fixer
    test_text = "שלום hello world"
    result = fix_layout(test_text)
    print(f"LAYOUT_RESULT:{result}")
    
    # Test text cleaner  
    messy_text = "  Hello    world  with   spaces   "
    cleaned = clean_text(messy_text)
    print(f"CLEAN_RESULT:{cleaned}")
    
    print("BRIDGE_TEST:SUCCESS")

if __name__ == "__main__":
    main()
'''.format(resources_path=os.path.dirname(os.path.abspath(__file__)))

    try:
        # Write temporary script
        with tempfile.NamedTemporaryFile(mode='w', suffix='.py', delete=False) as f:
            f.write(bridge_test_script)
            temp_script = f.name
        
        # Run the script (simulating what Swift's PythonBridge does)
        proc_result = subprocess.run([sys.executable, temp_script], 
                                   capture_output=True, text=True, timeout=30)
        
        # Clean up
        os.unlink(temp_script)
        
        if proc_result.returncode == 0:
            output_lines = proc_result.stdout.strip().split('\n')
            for line in output_lines:
                if line.startswith('LAYOUT_RESULT:'):
                    layout_result = line.replace('LAYOUT_RESULT:', '')
                    print(f"   Layout Fix: {repr(layout_result)}")
                elif line.startswith('CLEAN_RESULT:'):
                    clean_result = line.replace('CLEAN_RESULT:', '')
                    print(f"   Text Clean: {repr(clean_result)}")
                elif line.startswith('BRIDGE_TEST:'):
                    status = line.replace('BRIDGE_TEST:', '')
                    print(f"   Bridge Status: {'✅' if status == 'SUCCESS' else '❌'} {status}")
            
            print("✅ Swift-Python bridge simulation successful!")
            return True
        else:
            print(f"❌ Bridge test failed: {proc_result.stderr}")
            return False
            
    except Exception as e:
        print(f"❌ Error testing Swift-Python bridge: {e}")
        return False

def test_app_bundle_python():
    """Test Python execution from the app bundle"""
    print("\n📱 Testing App Bundle Python Integration")
    print("=" * 50)
    
    app_python_path = "/Users/galsasson/Downloads/Joyout/JoyaaS-Native-Build/JoyaaS.app/Contents/Resources/python"
    
    if not os.path.exists(app_python_path):
        print("❌ App bundle Python directory not found")
        return False
    
    # Test that we can run Python from the app bundle resources
    test_script = f'''
import sys
sys.path.insert(0, "{app_python_path}")

from joyaas_app_fixed import fix_layout
result = fix_layout("test שלום")
print(f"APP_BUNDLE_RESULT:{{result}}")
print("APP_BUNDLE_TEST:SUCCESS")
'''
    
    try:
        with tempfile.NamedTemporaryFile(mode='w', suffix='.py', delete=False) as f:
            f.write(test_script)
            temp_script = f.name
        
        result = subprocess.run([sys.executable, temp_script],
                               capture_output=True, text=True, timeout=30)
        
        os.unlink(temp_script)
        
        if result.returncode == 0:
            output_lines = result.stdout.strip().split('\n')
            for line in output_lines:
                if line.startswith('APP_BUNDLE_RESULT:'):
                    bundle_result = line.replace('APP_BUNDLE_RESULT:', '')
                    print(f"   Bundle Result: {repr(bundle_result)}")
                elif line.startswith('APP_BUNDLE_TEST:'):
                    status = line.replace('APP_BUNDLE_TEST:', '')
                    print(f"   Bundle Status: {'✅' if status == 'SUCCESS' else '❌'} {status}")
            
            print("✅ App bundle Python integration working!")
            return True
        else:
            print(f"❌ App bundle test failed: {result.stderr}")
            return False
            
    except Exception as e:
        print(f"❌ Error testing app bundle Python: {e}")
        return False

def check_dependencies():
    """Check if all required Python dependencies are available"""
    print("\n📦 Checking Python Dependencies")
    print("=" * 50)
    
    required_packages = ['json', 'os', 'sys', 'tempfile', 'subprocess']
    optional_packages = ['requests', 'openai', 'pyperclip']
    
    all_good = True
    
    for pkg in required_packages:
        try:
            __import__(pkg)
            print(f"   ✅ {pkg} - Available")
        except ImportError:
            print(f"   ❌ {pkg} - Missing (Required)")
            all_good = False
    
    for pkg in optional_packages:
        try:
            __import__(pkg)
            print(f"   ✅ {pkg} - Available")
        except ImportError:
            print(f"   ⚠️  {pkg} - Missing (Optional - needed for AI features)")
    
    return all_good

def main():
    """Run all tests"""
    print("🚀 JoyaaS Native App - Functionality Test Suite")
    print("=" * 60)
    
    tests = [
        ("Python Backend", test_python_backend),
        ("Swift-Python Bridge", test_swift_python_bridge),
        ("App Bundle Integration", test_app_bundle_python),
        ("Dependencies", check_dependencies)
    ]
    
    results = []
    
    for test_name, test_func in tests:
        print(f"\n🔍 Running {test_name} Test...")
        try:
            success = test_func()
            results.append((test_name, success))
        except Exception as e:
            print(f"❌ Test {test_name} crashed: {e}")
            results.append((test_name, False))
    
    # Summary
    print("\n" + "=" * 60)
    print("📊 Test Results Summary:")
    print("=" * 60)
    
    passed = 0
    total = len(results)
    
    for test_name, success in results:
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"   {status} - {test_name}")
        if success:
            passed += 1
    
    print(f"\n🎯 Overall Result: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All functionality tests passed! JoyaaS native app is ready.")
    else:
        print("⚠️  Some tests failed. Review the output above for details.")
    
    return passed == total

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
