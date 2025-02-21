set PENDULUM_EXTENSIONS=1

maturin build -vv -j %CPU_COUNT% --release --strip --manylinux off --interpreter=%PYTHON%

REM Bundle licenses
cargo-bundle-licenses --format yaml --output THIRDPARTY.yml

FOR /F "delims=" %%i IN ('dir /s /b rust\target\wheels\*.whl') DO set dlt_pendulum_wheel=%%i

%PYTHON% -m pip install --no-deps %dlt_pendulum_wheel% -vv
