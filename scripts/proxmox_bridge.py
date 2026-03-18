import os
from proxmoxer import ProxmoxAPI
from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(__file__), '../.env'))

def get_pve():
    return ProxmoxAPI(
        os.getenv("PVE_HOST"),
        user=os.getenv("PVE_USER"),
        token_name=os.getenv("PVE_TOKEN_NAME"),
        token_value=os.getenv("PVE_TOKEN_VALUE"),
        verify_ssl=False
    )

def self_heal(vmid):
    p = get_pve()
    print(f"🤖 AEF Sentry: Resetting VM {vmid}")
    p.nodes('pve').qemu(vmid).status.reboot.post()

if __name__ == "__main__":
    try:
        nodes = get_pve().nodes.get()
        print(f"✅ API Connection Successful. Nodes: {[n['node'] for n in nodes]}")
    except Exception as e:
        print(f"❌ Connection Failed: {e}")
