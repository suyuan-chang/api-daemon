// Android specific implementation of GenerationWorker

use crate::cgroups::{CGroupError, GenerationWorker};
use log::{debug, error};
use std::collections::HashSet;
use std::fs::{read_dir, File, OpenOptions};
use std::io::Write;
use std::path::Path;

const CGROUP_MEM: &str = "/dev/memcg/b2g";

fn get_all_pids() -> impl Iterator<Item = i32> {
    read_dir(Path::new("/proc"))
        .expect("fail to read /proc")
        .filter_map(|x| {
            let entry = x.as_ref().unwrap().path();
            if !entry.is_dir() {
                return None;
            }
            let cgroup_path = &(entry.to_str().unwrap())[6..];
            let firstchar = cgroup_path.chars().next().unwrap();
            if !firstchar.is_ascii_digit() {
                return None;
            }
            Some(cgroup_path.parse::<i32>().unwrap())
        })
}

pub struct CGroupsWorker();

impl CGroupsWorker {
    pub fn new() -> Self {
        CGroupsWorker()
    }
}

// Add & remove processes to cgroups.
//
// We don't support cgroup adding and removing yet.  The assumption is
// all cgroups are pre-created.  Attribute changing are not supported
// yet, too.
impl GenerationWorker for CGroupsWorker {
    fn remove_group(&mut self, _group_path: &str) -> Result<(), CGroupError> {
        // Not support yet!
        Ok(())
    }

    fn add_group(&mut self, _group_name: &str, _parent: &str) -> Result<(), CGroupError> {
        // Not support yet!
        Ok(())
    }

    fn update_group_attrs(
        &mut self,
        _group_path: &str,
        _to_set: &mut [(String, String)],
        _to_remove: &mut [String],
    ) -> Result<(), CGroupError> {
        // Not support yet!
        Ok(())
    }

    fn move_processes(
        &mut self,
        removings: &mut [i32],
        movings: &mut [(i32, String)],
    ) -> Result<(), CGroupError> {
        let pids: HashSet<_> = get_all_pids().collect();

        if !removings.is_empty() {
            let path = format!("{}/cgroup.procs", CGROUP_MEM);
            let mut file = OpenOptions::new()
                .write(true)
                .open(path)
                .expect("fail to open cgroup.procs");
            for pid in removings.iter().filter(|x| pids.contains(&x)) {
                if let Err(err) = write!(file, "{}", pid) {
                    error!("Failed to write to {}/cgroup.procs : {}", CGROUP_MEM, err);
                }
            }
        }

        if movings.is_empty() {
            return Ok(());
        }

        // Sorting by group_paths, an opened file object of a
        // cgroup.procs can be reused by following pids of the same
        // group if there are.
        movings.sort_by(|(_, x_path), (_, y_path)| x_path.cmp(&y_path));

        let unknown_pids = movings.iter().filter(|x| !pids.contains(&x.0));
        for (pid, group_path) in unknown_pids {
            debug!("Fail to add pid={} to {}", pid, group_path);
        }

        let mut last_name_file: Option<(&str, File)> = None;
        let known_pids = movings.iter().filter(|x| pids.contains(&x.0));
        for (pid, group_path) in known_pids {
            debug!("Move {} to {}", pid, group_path);
            if last_name_file.is_none() || !last_name_file.as_ref().unwrap().0.eq(group_path) {
                let path = format!("{}/{}/cgroup.procs", CGROUP_MEM, group_path);
                let file = OpenOptions::new()
                    .write(true)
                    .open(path)
                    .expect("fail to open cgroup.procs");
                last_name_file = Some((group_path, file));
            }
            let file = &mut last_name_file.as_mut().unwrap().1;

            if let Err(err) = write!(file, "{}", pid) {
                error!(
                    "Fail to write pid={} to {}/cgroup.procs : {}",
                    pid, group_path, err
                );
                return self.move_processes(removings, movings);
            }
        }
        Ok(())
    }
}
