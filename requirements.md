
Build the initial implementation of my robotics digital twin project. Create the files and configuration, run available checks, and document anything that cannot be verified on this machine.

## Project context

My thesis project, TWINX, will model a Unitree Go2 or G1 and a small laboratory environment. It must support ROS 2 algorithms, repeatable navigation experiments, and later quantitative comparison with the physical robot.

For this first milestone, build a working navigation prototype in Docker on Windows, with browser GUI access.

## Technology baseline

- Docker Desktop using Linux containers and the WSL 2 backend.
- Ubuntu 24.04, ROS 2 Jazzy, and Gazebo Harmonic.
- Nav2 for navigation.
- RViz for visualization.
- A virtual Linux desktop exposed through noVNC.
- Docker Compose for orchestration.

Verify current official documentation and compatible package names before implementation. Use modern Gazebo and `ros_gz`, avoiding Gazebo Classic packages.

## First milestone

Demonstrate a robot navigating autonomously between two points in a small simulated laboratory, avoiding a static obstacle.

Because the final Unitree model and locomotion controller are not yet selected, use a supported differential-drive robot for this initial infrastructure milestone. Clearly label it as a temporary navigation test platform. Do not claim it validates Unitree locomotion or sim-to-real performance.

Keep robot-specific configuration separate so a Unitree model and functioning locomotion controller can replace the temporary platform later.

## Implementation requirements

### 1. Repository structure

Create a maintainable structure containing:

- Dockerfiles and entrypoint scripts.
- `compose.yaml`.
- `.env.example` and `.gitignore`.
- ROS 2 packages for world/robot bringup and benchmark execution.
- Gazebo world and robot assets.
- ROS/Gazebo bridge configuration.
- Nav2 parameters, map files, and RViz configuration.
- A README with Windows PowerShell commands.
- Persistent directories for recordings and experiment results.

Use Linux line endings for scripts and ensure executables have correct permissions inside images.

### 2. Compose architecture

Prefer a small number of services initially:

- `simulator`: Gazebo server, robot spawning, required controllers, sensor simulation, and ROS/Gazebo bridges.
- `autonomy`: robot state publication where appropriate, localization, and Nav2.
- `desktop`: browser-accessible desktop with RViz and optional Gazebo GUI.
- `benchmark`: an on-demand ROS 2 navigation experiment runner.

Adjust service boundaries if needed for reliable graphical display or ROS discovery, and explain the decision.

Provide `sim`, `gui`, and `benchmark` profiles with documented commands. Reserve the future hardware backend architecture, but do not implement a fake hardware driver.

Use a shared Docker network and explicitly configure reliable ROS discovery. Do not assume Linux host networking works identically on Docker Desktop.

### 3. Browser GUI

Expose the desktop through noVNC at a documented localhost URL.

- Bind published access to `127.0.0.1`.
- Make RViz usable from the browser.
- Provide Gazebo GUI access if supported by the chosen display architecture.
- Configure the actual display connection between containers.
- Document authentication configuration without committing secrets.

Provide a software-rendering baseline for the simple demo and an optional NVIDIA GPU override if feasible. Distinguish GPU compute support from working OpenGL rendering. Do not require privileged containers or Docker socket access.

### 4. Robot and environment

Use an existing maintained robot model where practical.

Create a simple laboratory world with walls, a start pose, a destination, and an obstacle. Supply a matching static occupancy map for the first milestone.

Provide correctly configured:

- Laser scan.
- Odometry.
- Joint states.
- Robot description.
- `map → odom → base_link → sensor` transforms.
- Velocity commands.
- Simulation clock.

Avoid duplicate TF publishers. Verify the velocity message type expected by the selected Nav2 and controller versions.

Navigation must use estimated localization and ordinary sensor data. Keep simulator ground truth separate for evaluation.

### 5. Navigation

Configure AMCL and Nav2 for the provided map and robot.

Ensure:

- Simulation nodes use simulation time consistently.
- The initial pose is established reproducibly.
- Nav2 lifecycle nodes activate correctly.
- A navigation goal can be sent through RViz.
- The robot avoids the obstacle and reaches the goal.

Do not rely on fixed sleeps alone for startup. Check simulation, TF, sensors, localization, and Nav2 readiness with bounded timeouts and useful failure messages.

### 6. Repeatable benchmark

Implement one benchmark that:

1. Waits for readiness.
2. Places or resets the robot reproducibly.
3. Handles localization and navigation state correctly after reset.
4. Sends a predefined goal.
5. Detects success, failure, or timeout.
6. Records selected ROS topics.
7. Writes machine-readable results.

Record:

- Trial ID and scenario ID.
- Configuration and software version identifiers.
- Navigation outcome.
- Simulation elapsed time and wall-clock duration separately.
- Estimated path length, with its data source clearly identified.
- Final estimated goal position error.

Only report collisions or ground-truth error if the required measurement is implemented. Otherwise mark the metric unavailable; do not invent results.

Keep generated recordings and results outside disposable container storage.

### 7. Reproducibility and maintenance

- Pin dependency versions or source revisions where practical.
- Avoid fetching changing repository branches at every container startup.
- Document third-party assets and licenses.
- Use configurable ROS domain settings.
- Handle shutdown cleanly.
- Include health checks where they meaningfully verify readiness.
- Keep source code editable without rebuilding all dependencies.
- Do not add unrelated databases, Kubernetes, or cloud services.

## Validation

Perform checks in increasing order:

1. Validate Compose configuration.
2. Build images if Docker is available.
3. Verify ROS packages and launch files.
4. Start headless simulation.
5. Check clock, scan, odometry, TF, and command connectivity.
6. Verify browser desktop and RViz access.
7. Run the navigation benchmark.

If Docker, GPU support, internet access, or graphical verification is unavailable, complete the implementation and clearly distinguish static checks from runtime tests that remain unverified.

Do not describe the setup as working unless an end-to-end navigation run has actually succeeded.

## README and final handoff

Provide exact PowerShell commands for:

- Initial setup and environment configuration.
- Building images.
- Starting the browser GUI.
- Running navigation manually.
- Running the automated benchmark.
- Locating recordings and results.
- Stopping services without deleting experiment data.

Include troubleshooting for ROS discovery, missing transforms, Nav2 activation, black GUI screens, rendering performance, and mounted-file permissions.

Explain how this temporary robot will later be replaced by a Unitree Go2 or G1, including the need for a compatible locomotion controller and hardware interface.

Inspect the repository first, preserve existing work, and proceed with sensible defaults. Ask only about genuinely blocking choices. Finish with the files created, checks performed, limitations, and the next command I should run.
