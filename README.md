# Planetiler Fargate Example

## References

* **Planetiler** - https://github.com/onthegomap/planetiler
* **Fargate Task Example** - https://github.com/zhibek/fargate-task-example-cloudformation


## Prerequisites

### Set AWS access key environment variables
```
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export AWS_DEFAULT_REGION=eu-west-1
```


## Deloy & Run

### Setup
Setup the Fargate Task.
```
./deploy/task-setup.sh
```

### Run
Run the Fargate Task.
```
./deploy/task-run.sh
```

### Cleanup
Cleanup the Fargate Task when it is no longer required.
```
./deploy/task-cleanup.sh
```
