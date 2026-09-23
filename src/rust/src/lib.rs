use extendr_api::prelude::*;
use keepass::db::{Entry, Group};
use keepass::error::{DatabaseKeyError, DatabaseOpenError};
use keepass::{Database, DatabaseKey};
use std::fs::File;

/// Column-wise storage of all entries in a database.
#[derive(Default)]
struct Entries {
    uuid: Vec<String>,
    group_path: Vec<String>,
    title: Vec<Option<String>>,
    username: Vec<Option<String>>,
    password: Vec<Option<String>>,
    url: Vec<Option<String>>,
    notes: Vec<Option<String>>,
}

impl Entries {
    fn push(&mut self, entry: &Entry, group_path: &str) {
        // Fields that are absent from the entry become NA in R.
        let field = |value: Option<&str>| value.map(str::to_string);

        self.uuid.push(entry.uuid.to_string());
        self.group_path.push(group_path.to_string());
        self.title.push(field(entry.get_title()));
        self.username.push(field(entry.get_username()));
        self.password.push(field(entry.get_password()));
        self.url.push(field(entry.get_url()));
        self.notes.push(field(entry.get("Notes")));
    }

    /// Recursively collect the entries of `group` and all of its subgroups.
    fn collect(&mut self, group: &Group, parent_path: &str) {
        let path = if parent_path.is_empty() {
            group.name.clone()
        } else {
            format!("{}/{}", parent_path, group.name)
        };

        for entry in group.entries() {
            self.push(entry, &path);
        }

        for child in group.groups() {
            self.collect(child, &path);
        }
    }

    fn into_list(self) -> List {
        list!(
            uuid = self.uuid,
            group_path = self.group_path,
            title = self.title,
            username = self.username,
            password = self.password,
            url = self.url,
            notes = self.notes
        )
    }
}

fn open_error_message(err: DatabaseOpenError) -> String {
    match err {
        DatabaseOpenError::Key(DatabaseKeyError::IncorrectKey) => {
            "Incorrect password or keyfile.".to_string()
        }
        DatabaseOpenError::UnsupportedVersion => {
            "Unsupported KeePass database version.".to_string()
        }
        DatabaseOpenError::DatabaseIntegrity(e) => {
            format!("Not a valid KeePass database: {}", e)
        }
        e => format!("Failed to open database: {}", e),
    }
}

fn read_database(
    path: &str,
    password: Nullable<String>,
    keyfile: Nullable<String>,
) -> std::result::Result<List, String> {
    let mut key = DatabaseKey::new();

    if let NotNull(ref pw) = password {
        key = key.with_password(pw);
    }

    if let NotNull(ref kf_path) = keyfile {
        let mut kf_file =
            File::open(kf_path).map_err(|e| format!("Cannot open keyfile '{}': {}", kf_path, e))?;
        key = key
            .with_keyfile(&mut kf_file)
            .map_err(|e| format!("Cannot read keyfile '{}': {}", kf_path, e))?;
    }

    let mut file = File::open(path).map_err(|e| format!("Cannot open file '{}': {}", path, e))?;

    let db = Database::open(&mut file, key).map_err(open_error_message)?;

    let mut entries = Entries::default();
    entries.collect(&db.root, "");

    Ok(entries.into_list())
}

/// Returns `list(ok = <entries>, err = NULL)` on success and
/// `list(ok = NULL, err = <message>)` on failure, so that the error can be
/// raised on the R side without unwinding through Rust.
#[extendr]
fn kdbx_read_impl(path: &str, password: Nullable<String>, keyfile: Nullable<String>) -> List {
    match read_database(path, password, keyfile) {
        Ok(entries) => list!(ok = entries, err = NULL),
        Err(msg) => list!(ok = NULL, err = msg),
    }
}

extendr_module! {
    mod rkeepass;
    fn kdbx_read_impl;
}
