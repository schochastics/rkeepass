use extendr_api::prelude::*;
use keepass::{Database, DatabaseKey};
use std::fs::File;

fn collect_entries(
    group: &keepass::db::Group,
    parent_path: &str,
    uuids: &mut Vec<String>,
    group_paths: &mut Vec<String>,
    titles: &mut Vec<String>,
    usernames: &mut Vec<String>,
    passwords: &mut Vec<String>,
    urls: &mut Vec<String>,
    notes: &mut Vec<String>,
) {
    let current_path = if parent_path.is_empty() {
        group.name.clone()
    } else {
        format!("{}/{}", parent_path, group.name)
    };

    for entry in group.entries() {
        uuids.push(entry.uuid.to_string());
        group_paths.push(current_path.clone());
        titles.push(entry.get_title().unwrap_or("").to_string());
        usernames.push(entry.get_username().unwrap_or("").to_string());
        passwords.push(entry.get_password().unwrap_or("").to_string());
        urls.push(entry.get_url().unwrap_or("").to_string());
        notes.push(entry.get("Notes").unwrap_or("").to_string());
    }

    for child_group in group.groups() {
        collect_entries(
            child_group,
            &current_path,
            uuids,
            group_paths,
            titles,
            usernames,
            passwords,
            urls,
            notes,
        );
    }
}

#[extendr]
fn kdbx_read_impl(path: &str, password: Nullable<String>, keyfile: Nullable<String>) -> List {
    let mut key = DatabaseKey::new();

    if let NotNull(ref pw) = password {
        key = key.with_password(pw);
    }

    if let NotNull(ref kf_path) = keyfile {
        let mut kf_file = File::open(kf_path)
            .unwrap_or_else(|e| panic!("Cannot open keyfile '{}': {}", kf_path, e));
        key = key
            .with_keyfile(&mut kf_file)
            .unwrap_or_else(|e| panic!("Cannot read keyfile '{}': {}", kf_path, e));
    }

    let mut file = File::open(path)
        .unwrap_or_else(|e| panic!("Cannot open file '{}': {}", path, e));

    let db = Database::open(&mut file, key)
        .unwrap_or_else(|e| panic!("Failed to open database: {}", e));

    let mut uuids = Vec::new();
    let mut group_paths = Vec::new();
    let mut titles = Vec::new();
    let mut usernames = Vec::new();
    let mut passwords = Vec::new();
    let mut urls = Vec::new();
    let mut notes = Vec::new();

    collect_entries(
        &db.root,
        "",
        &mut uuids,
        &mut group_paths,
        &mut titles,
        &mut usernames,
        &mut passwords,
        &mut urls,
        &mut notes,
    );

    list!(
        uuid = uuids,
        group_path = group_paths,
        title = titles,
        username = usernames,
        password = passwords,
        url = urls,
        notes = notes
    )
}

extendr_module! {
    mod rkeepass;
    fn kdbx_read_impl;
}
