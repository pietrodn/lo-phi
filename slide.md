## The paper

![](images/title.pdf)\  

NDSS '16, 21-24 February 2016, San Diego, CA, USA

# Dynamic Malware Analysis: open challenges

## Dynamic Malware Analysis

Idea: **run the malware** in a sandbox (VM, debugger, ...) and use tools to analyze its behavior.

* We are interested in observing:
    * CPU instructions
    * Memory accesses
    * Network activity
    * Disk activity
* Observation tools must be placed **outside** the sandbox.
* At a **lower level** w.r.t. the malware.
* In theory, completely *transparent* to the malware.
* *Not so simple...*

## Virtualization is like dreaming

* Unsure if you're living in a dream, or awake?
    * Look for **artifacts** (i.e. anomalies) in your reality.

**Malware does the same**. They can tell whether they are being run in a VM by looking for *artifacts* in their environment.

![A possible artifact in the *Inception* movie.](images/inception.png){width=70%}

## Artifacts and environment-aware malware

**Observer effect**:

* Execution of software into a debugger or VM leaves *artifacts*.

**Artifacts** are evidences of an "artificial" environment.

* They can be reduced or be subtle, but still detectable.
* According to \cite{Garfinkel07}, *building a transparent VMM is fundamentally infeasible*.
* Malware can detect artifacts and hide its true behavior.

**Malware can resist to traditional dynamic analysis tools.** \vspace{1em}

If the malware "feels" that it's being analyzed, it could:

1. Remain inactive (not trigger the payload)
1. Abort or crash its host
1. Disable defenses or tools

## Artifacts: examples

\cite{Chen08}, \cite{Garfinkel07} provide a taxonomy of artifacts:

* **Hardware**
    * Special devices or adapters in VMs
    * Specific manufacturer prefixes on device names
    * Drivers and adapters for host-guest communication
* **Memory**
    * Hypervisors placing interrupt table in different position
    * Too little RAM (typical of VMs)
* **Software**
    * Presence of installed tools on the system
    * Suspicious registry keys
    * `isDebuggerPresent()` Windows API
* **Behaviour**
    * Timing differences (e.g. interception of privileged instructions in VMMs)

## Semantic Gap

Our aim is to **understand what the malware is doing**. Need to mine **semantics** from the extracted raw data.

* From raw data:
    * SATA frame *XYZ*
    * TCP packet *ABC*
    * Some bytes in RAM at `0xDEADBEEF`
* To concise, high-level event descriptions:
    * A file has been written
    * A connection has been opened

Tools used and modified for live analysis:

* Disk forensics: **Sleuthkit**
* Memory forensics: **Volatility**

## Malware Analysis Framework Evaluation

![From \cite{BareBox11}](images/evaluation-dimensions.pdf){height=60% width=60%}

Tradeoff between:

1. *Low-artifact, semantically poor* tools (Virtual Machine Introspection)
1. *High-artifact, semantically-rich* frameworks (debuggers)

# LO-PHI: Low-Observable Physical Host Instrumentation for Malware Analysis

## Goals

* **No virtualization**: run malware on bare metal machines!
    * Malware can "feel" the presence of VMs and debuggers.
    * Physical sensors and actuators.
* Bridging the **semantic gap**
    * Physical sensors collect raw data.
    * We need high-level, useful information.
* **Automated restore** to pre-infection state.
* **Stealthiness**: very few, undetectable artifacts.
* **Extendability**: support new OSs and filesystems.

## Threat model

Assumptions on our model of malware: they are **limitations** of the approach.

* Malware can interact with the system in any way
* Malicious modifications evident either in memory or on disk
* No infection delivered to hardware
* Malware not actively trying to thwart semantic-gap reconstruction
* Instrumentation is in place before malware is executed
    * Malware cannot analyze the system without LO-PHI in place.
    * Harder to compare and detect artifacts: **no baseline**.

## Sensors and actuators (1)

![Hardware instrumentation to inspect a bare-metal machine.](images/hardware-setup.pdf){height=95% width=95%}

## Sensors and actuators (2)

### Sensors

* **Memory**. Xilinx ML507 board connected to PCIe, reads and writes arbitrary memory locations via DMA.
* **Disk**. ML507 board intercepting all the traffic over SATA interface. Sends SATA frames via Gigabit Ethernet and UDP.
    * Completely passive...
    * except when SATA data rate exceeds Ethernet bandwidth: throttling of frames.
* **Network interface**. Mentioned in paper, but the technology used is unclear.

### Actuators

An Arduino Leonardo emulates **USB keyboard and mouse**.

## Infrastructure

### Restoring physical machines

* We cannot simply "restore a snapshot" like in VMs.
* **Preboot Execute Environment** (PXE) with **CloneZilla**
    * Allows to restore the disk to a previously saved state
    * No interaction with the OS
* Also, DNS and DHCP servers.

### Scalable infrastructure

* Job submission system: jobs are sent to a scheduler
* The scheduler executes the routine on an appropriate machine

## Common interface (1)

Python script for running a malware sample and collecting the appropriate raw data for analysis.

\hbeginenvir{scriptsize}
``` {.python .numberLines}
disk_tap.start()
# Send key presses to download binary
machine.keypress_send(ftp_script)
# Dump memory (clean)
machine.memory_dump(memory_file_clean)
network_tap.start()
# Get a list of current visible buttons
button_clicker.update_buttons()
# Start our binary and click any buttons
machine.keypress_send('SPECIAL:RETURN')
# Move our mouse to imitate a human
machine.mouse_wiggle(True)
time.sleep(MALWARE_START_TIME)
# ...
# Click any new buttons that appeared
button_clicker.click_buttons(new only=True)
time.sleep(MALWARE EXECUTION TIME-elapsed_time)
machine.screenshot(screenshot_two)
machine.memory dump(memory_file_dirty)
machine.power_shutdown()
```
\hendenvir{scriptsize}

## Common interface (2)

The framework supports:

* Real, physical machines
* Traditional Virtual-Machine Introspection

The abstracted software interface written in Python is the same.
We can focus on high-level functionality.

# Artifacts: quantitative analysis

## Memory throughput
![Average memory throughput comparison as reported by RAMSpeed, with and without instrumentation. Deviation from uninstrumented trial is only 0.4% in worst case.](images/mem-throughput.pdf)

## Disk throughput: reads

![File system read throughput comparison as reported by IOZone on Windows XP, with and without instrumentation on a physical machine.](images/file-reads.pdf)

## Disk throughput: writes

![There are significant differences for write throughput since here the cache does not help.](images/file-writes.pdf)

# Experiment: evasive malware

## Timing
![Time spent in each step of binary analysis. Both environments were booting a 10 GB Windows 7 (64-bit) hibernate image and were running on a system with 1 GB of volatile memory.](images/times.pdf){width=80% height=80%}

# Critique

## Known limitations

* New chipset use IOMMUs, **disabling DMA** from peripherals.
    * Current memory acquisition technique will become unusable.
* **Smearing**: the memory can change *during* the acquisition
    * Inconsistent states.
    * Faster polling rates can help.
* **Filesystem caching**: some data will not pass through SATA interface.
    * Malware could write a file to disk cache, execute and delete it before the cached is flushed to disk.
    * However the effects would be visible in memory.

## Limitations of the technique

* The malware is left to run only 3 minutes.
    * Many malwares need much more time to fully uncover their effects (e.g. ransomware).
* **No memory polling** during the execution of the malware.
    * Only snapshot before and after the execution.
    * Temporary data used by the malware is never seen.
* Assumption: **malware does not modify BIOS or firmware**.
    * But if it does, the physical machine could not be recoverable.
    * Costly!
* **No Internet access**: the authors always run the malware on disconnected machines.
    * Most malware becomes useless without Command&Control infrastructure.
    * Network access could expose further, unseen, artifacts.

## Methodological issues

* The article claims that the artifacts from LO-PHI are unusable by malware because there's **no baseline** (i.e. the malware cannot see the machine before the installation of LO-PHI).
    * This can also be true for traditional approaches.
* **No statistical test** used to discover whether difference in disk/memory throughput is statistically significant (presence of artifacts).
    * Very simple and standard procedure, should really be done in a scientific paper.
* **Network analysis** technique is not described and unclear.
    * *We exclude the network trace analysis from much of our discussion since it is a well-known technique and not the focus of our work.*

## Another point...

* **Virtualization is increasingly used** in production contexts.
    * Just think about **cloud computing**!
* Attackers will want to target also VMs.
* Malware that deactivates in VMs will be less common.

# Related and future work

## Related work

* Many dynamic malware analysis tools rely on virtualization: Ether, BitBlaze, Anubis, V2E, HyperDbg, SPIDER.
    * We already saw the limitations of VM approaches: **artifacts**.
* **BareBox** \cite{BareBox11}: malware analysis framework based on a bare-metal machine without virtualization or emulations.
    * Only targets user-mode malware.
    * Only disk analysis (no memory tools).

## Future evolutions

* The aim should be to do **automated, repeated** analyses.
    * **Disk restore** phase is the lengthiest (> 6 min): should be optimized.
    * *The resetting and boot process could be decreased significantly by writing a custom PXE loader, or completely mitigated by implementing copy-on-write into our FPGA.*
    * *While snapshots are trivial with virtual machines, it is still an open problem for physical machines.*
* Analyze transient behavior of binary: continuous memory polling.
    * Need to deal with DMA artifacts.
* Complete hardware coverage
    * Also analyze malware that infects BIOS and hardware.

## References
