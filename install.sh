if [ ! -d .venv ]; then
    python3.13 -m venv .venv
fi

source .venv/bin/activate
pip install --upgrade -r requirements.txt
