# Crypto Mining Server Setup

This is a guide on how to build and setup an Ethereum mining rig using Nvidia GTX 10 series GPUs using the Claymore Dual miner. You can easily mine other cryptos that the Claymore miner supports as well as install other miners to mine other coins.

## Compatibility

Tested on Ubuntu 16.04 Server LTS amd64 Xenial Xerus. Setup with [ubuntu-unattended](https://github.com/ki1cx/ubuntu-unattended)

## Requirements

* Clean Ubuntu server install

## Hardware List

Here is the list of hardware that I've use to build the rig. 

* **Motherboard** - MSI Pro Series Intel Z270 DDR4 HDMI USB 3 SLI ATX Motherboard [Z270 SLI PLUS](https://www.amazon.com/MSI-Z270-SLI-Motherboard-PLUS/dp/B01MR32I8L/)

* **CPU** - Intel CPU [BX80662G3900](https://www.amazon.com/gp/product/B01B2PJRPA) Celeron G3900 2.80Ghz 2M LGA1151 2C/2T Skylake

* **Memory** - CORSAIR Vengeance LPX 8GB (2x4GB) DDR4 DRAM 3000MHz C15 Memory Kit - Black [CMK8GX4M2B3000C15](https://www.amazon.com/gp/product/B0123ZBPDA/) (only need a single 4GB)

* **Power Supply** (PSU) - Corsair RMx Series, 850W, Fully Modular Power Supply, 80+ Gold Certified [RM850x](https://www.amazon.com/dp/B015YEI8JG)

* **SSD** - Transcend 64 GB SATA III MTS600 60 mm M.2 SSD [TS64GMTS600](https://www.amazon.com/gp/product/B00KLTPVJ0)

* **PCIe Risers** - [MintCell](https://www.amazon.com/gp/product/B06ZY2R85P) 6-Pack PCIe 6-Pin 16x to 1x Powered Riser Adapter Card w/ 60cm USB 3.0 Extension Cable & 6-Pin PCI-E to SATA Power Cable 

* **GPU** - Nvidia GTX 10 series GPUs

## Optional

* **USB Wifi Dongle** - [OURLINK](https://www.amazon.com/gp/product/B018TX8IDA) 600Mbps mini 802.11ac Dual Band 2.4G/5G Wireless Network Adapter USB Wi-Fi Dongle

	This is required if your rig will be connecting to the internet wirelessly. You'll still need to connect the server using LAN in order to setup the system initially.

* **PCIe Riser Adapter Board** - 4 in 1 PCI-E Riser [Adapter](https://www.amazon.com/RingBuu-Adapter-USB3-0-Rabbet-Ethereum/dp/B0756ZWGZX) Board USB3.0 PCI-E

	This is only required if your motherboard does not support as many PCIe slots as the number of GPUs you'll want to mine with. The MSI Z270 SLI Plus motherboard only comes with 6 PCIe slots. So you'll need the riser adapter board to increases the number of PCIe slots available to connect your GPUs to using the risers.

## On System Setup

1. Setup your base system (Motherboard , CPU, Memory, PSU, SSD) first.

2. Install Ubuntu Server. You can use the unattended setup detailed [here](https://github.com/ki1cx/ubuntu-unattended).

	Before installing Ubuntu, make sure your BIOS settings are as follows.
	
	* PEG0 - Max Link Speed - [Auto]
	* PEG1 - Max Link Speed - [Auto]
	* Above 4G memory/Crypto Currency mining - [Disabled]
	
		<img src="images/pre_gpu_bios_1.png" alt="open air" width="400px"/>
	
	* Initial Graphics Adapter - [PEG]
	
		<img src="images/pre_gpu_bios_2.png" alt="open air" width="400px"/>
		
	* Restore after AC Power Loss - [Power On]
	
		<img src="images/pre_gpu_bios_3.png" alt="open air" width="400px"/>
		
	* Disable all the settings on this screen
	
		<img src="images/pre_gpu_bios_4.png" alt="open air" width="400px"/>

	* Enable all the settings on this screen
	
		<img src="images/pre_gpu_bios_5.png" alt="open air" width="400px"/>
	
3. Git clone this repo

	* Edit install.sh and customize the following variables
	
		```bash
		powerDrawTarget=75
		temperatureTarget=58
		memoryTransferRateTarget=1300
		numberOfGPUs=8
		minimumHashRate=22
		startingFanSpeed=50
		```
	
	* Run install.sh
	
		This installs all the packages necessary to run the miner, including Nvidia drivers and cronjobs to automatically monitor the GPUs to maintain the proper powerdraw, temperature and hashrate.
		
		```
		sudo ./install.sh
		```
4. Turn system off completely, and install GPUS to the motherboard.

5. Go into BIOS and 

	* PEG0 - Max Link Speed - [Gen2]
	* PEG1 - Max Link Speed - [Gen2]
	* Above 4G memory/Crypto Currency mining - [Enabled]
	
		<img src="images/post_gpu_bios_1.png" alt="open air" width="400px"/>
		
	* Initial Graphics Adapter - [IGD]
	
		<img src="images/post_gpu_bios_2.png" alt="open air" width="400px"/>

6. Turn system back on

	Run the following command to check that your GPUs are recognized by the system. This is enough to get the miner to work with the GPUs.

	```bash
	nvidia-smi
	```
	
	Run the following command to check if X server can recognize the GPUs. This is required for overclocking.
	
	```bash
	XAUTHORITY=$(ps aux | grep [a]uth | awk '{print $17}')
	export XAUTHORITY
	export DISPLAY=:0
	nvidia-xconfig --query-gpu-info
	```

7. Plugin the USB Wifi Adapter to the motherboard

	USB Wifi Adapter is the last to be installed, because if installed first, the motherboard cannot detect the GPUs properly.

	* Install USB Wifi driver and enable
		
		If you are using the Wifi adapater mentioned below. This installs the rtl8812AU driver.
	
		```
		sudo ./setup_usb_wireless.sh
		```


## On GPU selection

When choosing GPUs to build with, here are the things to consider.

### Brand - Nvidia vs AMD

I chose to use Nvidia as opposed to AMD. From my research, Nvidia is much easier to overclock when using Linux. Although AMD has been the king for mining for sometime, Nvidia has a much more power efficient architecture, and it will save you on energy cost over time.

### GPU's Cooling method - blow style (fully enclosed case) vs open air (open case)

| Cooling | Example | Pros | Cons |
|---|---|---|---|
|  Open-Air  |  <img src="https://images-na.ssl-images-amazon.com/images/I/71QpPE6HUxL._SX522_.jpg" alt="open air" width="200px"/> [^1] | quiet, greater supply | dust accumulation, distributor markup |
| Closed / Blower  |   <img src="https://images-na.ssl-images-amazon.com/images/I/41jAgpWLOoL.jpg" alt="blow style" width="200px"/> [^2]  | solid construction, directed air flow, fixed price when purchased from manufacturer | noisy |
| Closed / Water-Cooled  |   <img src="https://thumbor.forbes.com/thumbor/960x0/smart/https%3A%2F%2Fblogs-images.forbes.com%2Fmarcochiappetta%2Ffiles%2F2015%2F05%2Fevga-titan.jpg" alt="blow style" width="200px"/> [^3]  | solid construction, directed air flow, silent | expensive |
	
I have tried the first two mentioned in the above table. If you are going to have a single rig of ~ 6 GPUS running in your bedroom, then the open air design will keep the noise down, because the fan does not have to run as fast compared to the closed air (blower) design. 
	
<img src="http://cdn.shopify.com/s/files/1/1952/1205/products/DSC_0030_1024x1024.jpg" alt="open air" width="200px"/>
	
If you are planning on a larger operation with ~ 100s of GPUs... then you'll probably want the blower style GPUs so you can carefuly direct the heat away from the heat sensitive components. 
	
<img src="https://i.pinimg.com/736x/fe/e8/94/fee894f88897840885e4bd36d6b4420e--rigs.jpg" alt="open air" width="200px"/>

### GPU Memory

Mining Ethereum requires DAG file to be uploaded to the GPU memory. Currently the DAG files is approaching 3GB, so purchasing a GPU with 6-8GB of memory will future proof your rig.

### Where to buy

Best place to buy Nvidia GPUs is to go to the [source](https://www.nvidia.com/en-us/geforce/products/10series/geforce-store/), since there are no additional markups. However, you'll likely need to wait until supply meets demand. If you want to get your hands on them sooner than later and don't mind the premium, then Amazon would be your best bet.

## On GPU Overclocking

### Controlling Memory speed

When mining Ethereum, you have to overclock the memeory speed to get performance boost. Modifying the memory transfer rate is easy the following. 

```bash
nvidia-settings -c :0 -a GPUMemoryTransferRateOffset[3]=<offset value to test>
```

Here is what I found to work in giving me a boost while remaining stable. I have not had a chance to try an 1080 Ti yet. 1080 (yes without the Ti) is widely known to be not good for mining due to it's GDDR5X memory.

| GPU | GPUMemoryTransferRateOffset |
|---|---|
| 1060 | 1300 | 
| 1070 | 1400 | 

### Controlling Power Draw

Giving the GPU enough is a crucial step in stablizing the GPU

```bash
//set persistence mode on
nvidia-smi -pm 1

//set upper power limit in watts
nvidia-smi -pl 75
```

The following chart shows the power limit I've used to stablize the GPUMemoryTransferRateOffset used above.

| GPU | Power Limit |
|---|---|
| 1060 | 75 | 
| 1070 | 100 | 

### Ethereum Hashrates

The GTX 1070s is a clear winner when it comes to mining Ethereum.

| GPU | Default | Overclocked | Price | cost per MH/s|
|---|---|---|---|---|
| 1060 | 18 MH/s | 23 MH/s| $299 | $13 |
| 1070 | 25 MH/s | 31 MH/s| $399 | $12 |
| 1080 Ti | 32 MH/s | 36 MH/s| $699 | $19 |

### Controling the fan speed

In order to control the fan speed, you'll need to set manual mode, which means the GPU will no longer automatically adjust the fan speed to the changing temperature. Make sure you are frequently running the custom script that adjusts the fan speed included in the repo or a custom script of your own.

```bash
//set fan speed across all GPUs
nvidia-settings -c :0 -a GPUFanControlState=1 -a GPUTargetFanSpeed=50

//set fan speed on a specific GPUs where <index> 
//should be replaced by the gpu you are targetting
nvidia-settings -c :0 -a [gpu:<index>]/GPUFanControlState=1 -a [fan:<index>]/GPUTargetFanSpeed=100
```

## On USB Wifi Adapters

Make sure you find one that is compatible with linux. Manufacturers may claim it works on Linux with the provided drivers, but I found them not trustworthy. I ended up finding a usable driver on github.

## On PCIe Risers

When choosing PCIe risers, make sure they are **VER 006C** or higher. Specifically, check if they have 4 high quality solid capacitors for voltage regulation and overcurrent protection. Also, chances are that 1 in 6 risers will be bad, so buy them in bulk to keep cost down.

## License
MIT

## References

[^1]: https://www.amazon.com/EVGA-GeForce-Support-Graphics-06G-P4-6267-KR/dp/B01LYN9KK6
[^2]: https://www.nvidia.com/en-us/geforce/products/10series/geforce-store/
[^3]: https://www.forbes.com/sites/marcochiappetta/2015/05/29/evga-steps-out-with-custom-water-cooled-geforce-gtx-titan-x-graphics-card/#17db683c6787


