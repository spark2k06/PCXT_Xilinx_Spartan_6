import os
import subprocess
import datetime
import time
import threading
import shutil

current_directory = os.getcwd()

max_threads = 3
build_queue = []

def execute_build(build_path):   
    build_dir = os.path.dirname(build_path)
    os.chdir(build_dir)
    print(build_path)        
    p = subprocess.Popen('start /wait cmd /c "{} 2> error.log"'.format(build_path), shell=True)
    p.communicate()
    os.chdir(current_directory)
    error_path = os.path.join(build_dir, 'error.log')
    if os.path.exists(error_path):
        error_text = ''
        with open(error_path, 'r') as f:
            error_text = f.read()

        if error_text:
            subdir_name = os.path.basename(os.path.dirname(build_path))
            pos = error_text.find('.""')
            if pos != -1:
                error_text = error_text[:pos+2]
                with open('error_{}.log'.format(subdir_name), 'w') as f:
                    f.write(error_text)

            else:            
                shutil.copy(error_path, 'error_{}.log'.format(subdir_name))

            os.chdir(build_dir)
            subprocess.Popen('start /wait cmd /c "{}"'.format(os.path.join(build_dir, 'clean.bat')), shell=True)
        os.remove(error_path)

def run_builds():
    lock = threading.Lock()
    while len(build_queue) > 0:
        lock.acquire()
        if len(build_queue) > 0:
            build_path = build_queue.pop(0)
            lock.release()
            execute_build(build_path)

        else:
            lock.release()
            break

if __name__ == '__main__':
    threads = []
    for root, dirs, files in os.walk(os.getcwd()):
        for file in files:
            if file.endswith('build.bat'):
                build_queue.append(os.path.join(root, file))

    while len(build_queue) > 0:
        if len(threads) < max_threads:
            t = threading.Thread(target=run_builds)
            threads.append(t)            
            time.sleep(1)
            t.start()            
        else:
            for t in threads:
                t.join()
                threads.remove(t)
                break

    for t in threading.enumerate():
        if t is not threading.current_thread():
            t.join()
