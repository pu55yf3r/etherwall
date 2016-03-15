#include "gethlog.h"
#include <QDebug>
#include <QSettings>
#include <QApplication>
#include <QClipboard>

namespace Etherwall {

    GethLog::GethLog() :
        QAbstractListModel(0), fList(), fProcess(0)
    {
    }

    QHash<int, QByteArray> GethLog::roleNames() const {
        QHash<int, QByteArray> roles;
        roles[MsgRole] = "msg";

        return roles;
    }

    int GethLog::rowCount(const QModelIndex & parent __attribute__ ((unused))) const {
        return fList.length();
    }

    QVariant GethLog::data(const QModelIndex & index, int role __attribute__ ((unused))) const {
        return fList.at(index.row());
    }

    void GethLog::saveToClipboard() const {
        QString text;

        foreach ( const QString& info, fList ) {
            text += (info + QString("\n"));
        }

        QApplication::clipboard()->setText(text);
    }

    void GethLog::attach(QProcess* process) {
        fProcess = process;
        connect(fProcess, &QProcess::readyReadStandardOutput, this, &GethLog::readStdout);
        connect(fProcess, &QProcess::readyReadStandardError, this, &GethLog::readStderr);
    }

    void GethLog::readStdout() {
        const QByteArray ba = fProcess->readAllStandardOutput();
        const QString str = QString::fromUtf8(ba);
        beginInsertRows(QModelIndex(), fList.size(), fList.size());
        fList.append(str);
        endInsertRows();
        overflowCheck();
    }

    void GethLog::readStderr() {
        const QByteArray ba = fProcess->readAllStandardError();
        const QString str = QString::fromUtf8(ba);
        beginInsertRows(QModelIndex(), fList.size(), fList.size());
        fList.append(str);
        endInsertRows();
        overflowCheck();
    }

    void GethLog::overflowCheck() {
        if ( fList.length() > 10 ) {
            beginRemoveRows(QModelIndex(), 0, 0);
            fList.removeAt(0);
            endRemoveRows();
        }
    }

}
