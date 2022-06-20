# Specify parent image. Please select a fixed tag here.
# ARG BASE_IMAGE=registry.git.rwth-aachen.de/jupyter/profiles/rwth-courses:latest
ARG BASE_IMAGE=jupyter/minimal-notebook
FROM $BASE_IMAGE

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    firefox \
    build-essential && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY start.sh start-notebook.sh start-singleuser.sh /usr/local/bin/
RUN chmod 777 /usr/local/bin/start*

USER ${NB_UID}

# Install Python 3 packages
RUN arch=$(uname -m) && \
    if [ "${arch}" == "aarch64" ]; then \
        # Prevent libmamba from sporadically hanging on arm64 under QEMU
        # <https://github.com/mamba-org/mamba/issues/1611>
        export G_SLICE=always-malloc; \
    fi && \
    # To remove the pinned python 3.10
    rm /opt/conda/conda-meta/pinned && \ 
    source activate base
RUN mamba install --yes -c robostack -c conda-forge \
    'python=3.9' \
    'mamba_gator' \
    'catkin_tools' \
    'pkg-config' \ 
    'make' \
    'ninja' \
    'nodejs' \
    'jupyterlab' \ 
    'jupyterlab-ros' \
    'jupyter-ros' \ 
    'ipywidgets' \
    'ros-noetic-desktop' \
    'ros-noetic-moveit-ros-move-group' \
    'ros-noetic-moveit-ros-perception' \
    'ros-noetic-moveit-fake-controller-manager' \
    'ros-noetic-moveit-planners-ompl' && \
    mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

ENV ROS_IP=127.0.0.1

WORKDIR "${HOME}"

ENTRYPOINT [ "tini", "-g", "--" ]
CMD [ "/usr/local/bin/start-notebook.sh" ]